# frozen_string_literal: true

namespace :lint do
  desc 'Check for incorrect apostrophe characters in french translation files'
  task :apostrophe do
    # Correct apostrophe: ’ (U+2019 RIGHT APOSTROPHE)
    # Incorrect apostrophe: ' (U+0027 SIMPLE QUOTE)

    # Incorrect apostrophe character: U+0027 (') SIMPLE QUOTE
    incorrect_apos = "'"
    correct_apos = "\u2019"

    # Common french elision patterns where apostrophes are used
    # These patterns match a letter followed by an incorrect apostrophe followed by a vowel or 'h'
    # which indicates a french elision (l'exemple, d'abord, n'est, etc.)
    # % is included to catch elisions before YAML interpolation variables (e.g. qu'%{profile})
    vowels_and_h = "aeiouyàâäéèêëïîôùûüœæAEIOUYÀÂÄÉÈÊËÏÎÔÙÛÜŒÆhH%"

    elision_patterns = [
      # Single letter elisions: l', d', n', s', c', j', m', t'
      /[ldnscjmtLDNSCJMT][#{incorrect_apos}][#{vowels_and_h}]/,
      # qu' elisions: qu'il, qu'elle, qu'on, jusqu'à, lorsqu'il, puisqu'on, quelqu'un, etc.
      /[Qq]u[#{incorrect_apos}][#{vowels_and_h}]/,
    ]

    fix_mode = (ENV['FIX'] == '1')

    files = Dir.glob('config/locales/**/*.fr.yml') + Dir.glob('config/locales/**/fr.yml') + Dir.glob('app/components/**/*.fr.yml')
    offenses = []
    fixed_files = []

    files.each do |file|
      content = File.read(file)
      original_content = content.dup
      lines = content.lines

      lines.each_with_index do |line, index|
        line_number = index + 1

        elision_patterns.each do |pattern|
          line.scan(pattern) do
            match_data = Regexp.last_match
            offenses << {
              file: file,
              line: line_number,
              column: match_data.begin(0) + 1,
              match: match_data[0],
              context: line.strip,
            }
          end
        end
      end

      if fix_mode
        fixed_content = content
        elision_patterns.each do |pattern|
          fixed_content = fixed_content.gsub(pattern) { |match| match.gsub(incorrect_apos, correct_apos) }
        end

        if fixed_content != original_content
          File.write(file, fixed_content)
          fixed_files << file
        end
      end
    end

    # Remove duplicates (same file, line, and match)
    offenses.uniq! { |o| [o[:file], o[:line], o[:match]] }

    if offenses.any?
      offenses.group_by { |o| o[:file] }.each do |file, file_offenses|
        puts "  #{file}:"
        file_offenses.each do |offense|
          puts "    Line #{offense[:line]}: #{offense[:match].inspect} in \"#{offense[:context].truncate(60)}\""
        end
        puts
      end

      if fix_mode
        puts "✅ Fixed #{offenses.size} incorrect apostrophe(s) in #{fixed_files.size} file(s)"
      else
        puts "\n❌ Found #{offenses.size} incorrect apostrophe(s) in french translation files:"
        puts "To fix, replace: ' (U+0027 SIMPLE QUOTE) → ' (U+2019 RIGHT APOSTROPHE )"
        puts "Or run: bundle exec rake lint:apostrophe:fix"
        puts
        exit 1
      end
    else
      puts "✅ No incorrect apostrophes found in french translation files"
    end
  end

  desc 'Fix incorrect apostrophe characters in french translation files'
  task 'apostrophe:fix' do
    ENV['FIX'] = '1'
    Rake::Task['lint:apostrophe'].invoke
  end
end
