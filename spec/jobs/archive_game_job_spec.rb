require 'rails_helper'
RSpec.fdescribe ArchiveGameJob, type: :job do

  describe '#perform' do
    context 'when there are stale games' do
      let(:expected_archived_size) { 2 }
      before do
        create :game
        create :started_game
        create :finished_game
        create :archived_game
        create :stale_game
      end
      it 'updates the archived_at column for that game and saves' do
        job = described_class.new
        job.perform
        expect(Game.all.where.not(archived_at: nil).size).to eq expected_archived_size
      end

      it 'is idempotent' do
        job = described_class.new
        job.perform
        sleep 3
        job.perform
        expect(Game.all.where.not(archived_at: nil).size).to eq expected_archived_size
      end

      # it 'broadcasts updates to users' do
      #   job = described_class.new
      #   expect {
      #     perform_enqueued_jobs do
      #       job.perform
      #     end
      #   }.to have_broadcasted_to("games")
      # end
    end
  end
end
