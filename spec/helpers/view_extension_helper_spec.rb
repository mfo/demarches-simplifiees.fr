# frozen_string_literal: true

describe ViewExtensionHelper do
  describe '#render_view_extensions' do
    let(:point) { :test_point }
    let(:enabled) { true }

    before do
      stub_const(
        'ViewExtensionHelper::EXTENSIONS',
        { point => [{ partial: 'shared/test_extension', enabled: -> { enabled } }] }
      )
      allow(helper).to receive(:render).with(partial: 'shared/test_extension', locals: { user: 'u' }).and_return('<b>contributed</b>'.html_safe)
    end

    subject { helper.render_view_extensions(point, user: 'u') }

    context 'when the contributing feature is enabled' do
      it { is_expected.to eq('<b>contributed</b>') }
    end

    context 'when the contributing feature is disabled' do
      let(:enabled) { false }

      it 'renders nothing rather than the partial' do
        expect(subject).to eq('')
        expect(helper).not_to have_received(:render)
      end
    end

    context 'when the point is unknown' do
      it 'raises rather than silently rendering nothing' do
        expect { helper.render_view_extensions(:nope) }.to raise_error(KeyError)
      end
    end
  end

  describe 'EXTENSIONS' do
    it 'points at partials that exist' do
      described_class::EXTENSIONS.each_value do |contributions|
        contributions.each do |contribution|
          directory, name = contribution[:partial].split('/')

          expect(helper.lookup_context.exists?(name, [directory], true))
            .to be(true), "missing partial #{contribution[:partial]}"
        end
      end
    end
  end
end
