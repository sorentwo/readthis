require 'readthis/notifications'

RSpec.describe Readthis::Notifications do
  describe '#instrument' do
    it 'yields the provided block' do
      inner = double(:inner)

      expect(inner).to receive(:call)

      Readthis::Notifications.instrument('operation', key: 'key') do
        inner.call
      end
    end
  end
end
