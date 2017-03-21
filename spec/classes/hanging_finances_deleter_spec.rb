require 'rails_helper'

RSpec.describe HangingFinancesDeleter do
  describe '.run' do
    context 'when there is finance with nil value after finance with value 100' do
      it 'treats nil finance as hanging finance and deletes it'
    end
    context 'when there is finance with 0 value after finance with value 100' do
      it 'treats 0 finance as hanging finance and deletes it'
    end
    context 'when there is a finance with value 1 after finance with value 100' do
      it 'does not treat this finance as hanging finance'
    end
    context 'when there is finance with nil value before finance with value 100' do
      it 'treats nil finance as hanging finance and deletes it'
    end
    context 'when there is finance with 0 value before finance with value 100' do
      it 'treats 0 finance as hanging finance and deletes it'
    end
    context 'when there is a finance with value 1 before finance with value 100' do
      it 'does not treat this finance as hanging finance'
    end




    # context 'when there are no hanging finances' do
    #   it 'does not delete any finances'
    # end
    # context 'when there are yearly hanging finances before real finances' do
    #   it 'deletes hanging finances'
    # end
    # context 'when there are yearly hanging finances after real finances' do
    #   it 'deletes hanging finances'
    # end
    context 'when there is only nil finance and 0 finance' do
      it 'delete finances'
    end
    context 'when there are only hanging finances' do
      it 'deletes hanging finances'
    end
  end
end
