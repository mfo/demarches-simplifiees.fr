# frozen_string_literal: true

describe ContactForm do
  describe 'question_type validation' do
    let(:user) { create(:user) }

    it 'accepts valid public question_type' do
      form = ContactForm.new(question_type: ContactForm::TYPE_INFO, subject: 'Test', text: 'Test', user:)
      form.valid?
      expect(form.errors[:question_type]).to be_empty
    end

    it 'accepts valid admin question_type' do
      form = ContactForm.new(question_type: ContactForm::ADMIN_TYPE_RDV, subject: 'Test', text: 'Test', user:, for_admin: true)
      form.valid?
      expect(form.errors[:question_type]).to be_empty
    end

    it 'rejects arbitrary question_type' do
      form = ContactForm.new(question_type: 'malicious_type', subject: 'Test', text: 'Test', user:)
      expect(form).not_to be_valid
      expect(form.errors[:question_type]).to be_present
    end
  end

  describe 'normalization' do
    it 'strips subject and text' do
      form = ContactForm.new(subject: '  Hello  ', text: "  world\n")
      expect(form.subject).to eq('Hello')
      expect(form.text).to eq('world')
    end

    it 'sanitizes email' do
      form = ContactForm.new(email: '  Foo@Example.COM ')
      expect(form.email).to eq('foo@example.com')
    end
  end
end
