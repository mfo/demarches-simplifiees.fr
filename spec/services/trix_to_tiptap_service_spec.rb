# frozen_string_literal: true

describe TrixToTiptapService do
  let(:resolver) do
    -> (text) do
      text.split(/(--[^-]+--)/).filter_map do |part|
        if part.empty?
          nil
        elsif part.start_with?('--') && part.end_with?('--')
          id = part.delete('-')
          { "type" => "mention", "attrs" => { "id" => id, "label" => id } }
        else
          { "type" => "text", "text" => part }
        end
      end
    end
  end
  let(:service) { described_class.new(inline_resolver: resolver) }

  it 'converts a simple Trix paragraph' do
    doc = service.to_document('<div>Bonjour</div>')
    expect(doc).to eq({
      "type" => "doc",
      "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Bonjour" }] }],
    })
  end

  it 'converts bold / italic into marks and keeps struck-through text as normal' do
    doc = service.to_document('<div><strong>a</strong><em>b</em><del>c</del></div>')
    inline = doc["content"].first["content"]
    expect(inline).to eq([
      { "type" => "text", "text" => "a", "marks" => [{ "type" => "bold" }] },
      { "type" => "text", "text" => "b", "marks" => [{ "type" => "italic" }] },
      { "type" => "text", "text" => "c" },
    ])
  end

  it 'converts a link into a link mark' do
    doc = service.to_document('<div><a href="https://x.fr">clic</a></div>')
    inline = doc["content"].first["content"]
    expect(inline).to eq([
      { "type" => "text", "text" => "clic", "marks" => [{ "type" => "link", "attrs" => { "href" => "https://x.fr" } }] },
    ])
  end

  it 'converts a bullet list' do
    doc = service.to_document('<ul><li>un</li><li>deux</li></ul>')
    expect(doc["content"]).to eq([
      {
        "type" => "bulletList",
        "content" => [
          { "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "un" }] }] },
          { "type" => "listItem", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "deux" }] }] },
        ],
      },
    ])
  end

  it 'converts an ordered list' do
    doc = service.to_document('<ol><li>un</li></ol>')
    expect(doc["content"].first["type"]).to eq("orderedList")
  end

  it 'converts a Trix h1 title into a level-2 heading' do
    doc = service.to_document('<h1>Titre</h1>')
    expect(doc["content"].first).to eq({
      "type" => "heading", "attrs" => { "level" => 2 },
      "content" => [{ "type" => "text", "text" => "Titre" }],
    })
  end

  it 'converts a mention via the resolver' do
    doc = service.to_document('<div>Nº --dossiernumber--</div>')
    expect(doc["content"].first["content"]).to eq([
      { "type" => "text", "text" => "Nº " },
      { "type" => "mention", "attrs" => { "id" => "dossiernumber", "label" => "dossiernumber" } },
    ])
  end

  it 'ignores underline (keeps the text)' do
    doc = service.to_document('<div><u>a</u></div>')
    expect(doc["content"].first["content"]).to eq([{ "type" => "text", "text" => "a" }])
  end

  it 'converts <br> into a hardBreak' do
    doc = service.to_document('<div>a<br>b</div>')
    expect(doc["content"].first["content"]).to eq([
      { "type" => "text", "text" => "a" },
      { "type" => "hardBreak" },
      { "type" => "text", "text" => "b" },
    ])
  end

  it 'returns a doc with an empty paragraph for empty HTML' do
    expect(service.to_document('')).to eq({ "type" => "doc", "content" => [{ "type" => "paragraph" }] })
  end

  it 'turns a blank line (<div><br></div>) into an empty paragraph, without a hardBreak' do
    doc = service.to_document('<div>a</div><div><br></div><div>b</div>')
    expect(doc["content"]).to eq([
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
      { "type" => "paragraph" },
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "b" }] },
    ])
  end

  it 'collapses consecutive empty paragraphs into one' do
    doc = service.to_document('<div>a</div><div><br></div><div><br></div><div><br></div><div>b</div>')
    expect(doc["content"]).to eq([
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
      { "type" => "paragraph" },
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "b" }] },
    ])
  end

  it 'drops leading and trailing empty paragraphs' do
    doc = service.to_document('<div><br></div><div>a</div><div><br></div>')
    expect(doc["content"]).to eq([
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }] },
    ])
  end

  it 'collapses consecutive <br> inside a block' do
    doc = service.to_document('<div>a<br><br><br>b</div>')
    expect(doc["content"].first["content"]).to eq([
      { "type" => "text", "text" => "a" },
      { "type" => "hardBreak" },
      { "type" => "text", "text" => "b" },
    ])
  end

  it 'drops a trailing <br> in a block' do
    doc = service.to_document('<div>a<br></div>')
    expect(doc["content"].first).to eq({
      "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a" }],
    })
  end

  it 'treats newlines inside a block as spaces, like the legacy HTML rendering' do
    doc = service.to_document("<p>a\nb</p>")
    expect(doc["content"]).to eq([
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a b" }] },
    ])
  end

  it 'collapses consecutive newlines into a single space' do
    doc = service.to_document("<p>a\n\n\nb</p>")
    expect(doc["content"]).to eq([
      { "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a b" }] },
    ])
  end

  it 'collapses indentation (multiple spaces) into a single space' do
    doc = service.to_document("<p>a    b</p>")
    expect(doc["content"].first).to eq({
      "type" => "paragraph", "content" => [{ "type" => "text", "text" => "a b" }],
    })
  end
end
