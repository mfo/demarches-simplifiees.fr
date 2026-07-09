# frozen_string_literal: true

describe DateDetectionUtils do
  describe '.convert_to_iso8601_date' do
    it 'accepts ISO 8601 formats' do
      expect(described_class.convert_to_iso8601_date('2023-12-21')).to eq('2023-12-21')
      expect(described_class.convert_to_iso8601_date('2023/12/21')).to eq('2023-12-21')
      expect(described_class.convert_to_iso8601_date('2023-4-3')).to eq('2023-04-03')
    end

    it 'accepts French/EU day-first formats' do
      expect(described_class.convert_to_iso8601_date('31/12/2017')).to eq('2017-12-31')
      expect(described_class.convert_to_iso8601_date('31-12-2017')).to eq('2017-12-31')
      expect(described_class.convert_to_iso8601_date('31.12.2017')).to eq('2017-12-31')
      expect(described_class.convert_to_iso8601_date('3/4/2023')).to eq('2023-04-03')
    end

    it 'prefers the French day-first interpretation for ambiguous dates' do
      expect(described_class.convert_to_iso8601_date('03/04/2023')).to eq('2023-04-03')
      expect(described_class.convert_to_iso8601_date('03-04-2023')).to eq('2023-04-03')
    end

    it 'accepts unambiguous US month-first formats' do
      expect(described_class.convert_to_iso8601_date('12/25/2023')).to eq('2023-12-25')
      expect(described_class.convert_to_iso8601_date('12-21-2023')).to eq('2023-12-21')
    end

    it 'rejects invalid input' do
      expect(described_class.convert_to_iso8601_date(nil)).to be_nil
      expect(described_class.convert_to_iso8601_date('')).to be_nil
      expect(described_class.convert_to_iso8601_date('value')).to be_nil
      expect(described_class.convert_to_iso8601_date('2023-27-02')).to be_nil
      expect(described_class.convert_to_iso8601_date('13/13/2023')).to be_nil
      expect(described_class.convert_to_iso8601_date('31/02/2023')).to be_nil
      expect(described_class.convert_to_iso8601_date('21/12/23')).to be_nil
      expect(described_class.convert_to_iso8601_date('2023-12-21T03:20')).to be_nil
      expect(described_class.convert_to_iso8601_date('1700000000')).to be_nil
    end
  end

  describe '.parsable_iso8601_date?' do
    it 'detects parsable dates' do
      expect(described_class.parsable_iso8601_date?('2023-12-21')).to be true
      expect(described_class.parsable_iso8601_date?('31/12/2017')).to be true
      expect(described_class.parsable_iso8601_date?('31.12.2017')).to be true
      expect(described_class.parsable_iso8601_date?('12/25/2023')).to be true
      expect(described_class.parsable_iso8601_date?(nil)).to be false
      expect(described_class.parsable_iso8601_date?('value')).to be false
      expect(described_class.parsable_iso8601_date?('2023-12-21T03:20')).to be false
    end
  end

  describe '.convert_to_iso8601_datetime' do
    it 'accepts ISO 8601 datetimes' do
      expect(described_class.convert_to_iso8601_datetime('2023-12-21T03:20')).to eq(Time.zone.parse('2023-12-21T03:20').iso8601)
      expect(described_class.convert_to_iso8601_datetime('2023-12-21T03:20:07+01:00')).to eq(Time.zone.parse('2023-12-21T03:20:07+01:00').iso8601)
    end

    it 'accepts space-separated ISO dates with time' do
      expect(described_class.convert_to_iso8601_datetime('2023-12-21 03:20')).to eq(Time.zone.parse('2023-12-21T03:20').iso8601)
      expect(described_class.convert_to_iso8601_datetime('2023-12-21 03:20:45')).to eq(Time.zone.parse('2023-12-21T03:20:45').iso8601)
    end

    it 'accepts French/EU day-first dates with time' do
      expect(described_class.convert_to_iso8601_datetime('21/12/2023 03:20')).to eq(Time.zone.parse('2023-12-21T03:20').iso8601)
      expect(described_class.convert_to_iso8601_datetime('21-12-2023 03:20')).to eq(Time.zone.parse('2023-12-21T03:20').iso8601)
      expect(described_class.convert_to_iso8601_datetime('21.12.2023 03:20:45')).to eq(Time.zone.parse('2023-12-21T03:20:45').iso8601)
    end

    it 'prefers the French day-first interpretation for ambiguous dates' do
      expect(described_class.convert_to_iso8601_datetime('03/04/2023 10:00')).to eq(Time.zone.parse('2023-04-03T10:00').iso8601)
    end

    it 'accepts unambiguous US month-first dates with time' do
      expect(described_class.convert_to_iso8601_datetime('12/25/2023 03:20')).to eq(Time.zone.parse('2023-12-25T03:20').iso8601)
      expect(described_class.convert_to_iso8601_datetime('12-21-2023 03:20')).to eq(Time.zone.parse('2023-12-21T03:20').iso8601)
    end

    it 'accepts a bare date as midnight local time' do
      expect(described_class.convert_to_iso8601_datetime('2023-12-21')).to eq(Time.zone.parse('2023-12-21').iso8601)
      expect(described_class.convert_to_iso8601_datetime('21/12/2023')).to eq(Time.zone.parse('2023-12-21').iso8601)
    end

    it 'accepts the rails multiparameter form format' do
      expect(described_class.convert_to_iso8601_datetime('{3=>21, 2=>12, 1=>2023, 4=>3, 5=>20}')).to eq(Time.zone.parse('2023-12-21T03:20').iso8601)
    end

    it 'rejects invalid input' do
      expect(described_class.convert_to_iso8601_datetime(nil)).to be_nil
      expect(described_class.convert_to_iso8601_datetime('')).to be_nil
      expect(described_class.convert_to_iso8601_datetime('value')).to be_nil
      expect(described_class.convert_to_iso8601_datetime('13/13/2023 03:20')).to be_nil
      expect(described_class.convert_to_iso8601_datetime('21/12/2023 25:20')).to be_nil
    end
  end

  describe '.parsable_iso8601_datetime?' do
    it 'detects parsable datetimes' do
      expect(described_class.parsable_iso8601_datetime?('2023-12-21T03:20')).to be true
      expect(described_class.parsable_iso8601_datetime?('21/12/2023 03:20')).to be true
      expect(described_class.parsable_iso8601_datetime?('value')).to be false
      expect(described_class.parsable_iso8601_datetime?(nil)).to be false
    end
  end
end
