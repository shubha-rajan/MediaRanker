class Work < ApplicationRecord
  validates :title, presence: true
  validates :creator, presence: true
  validates :category, presence: true, inclusion: { in: %w(album book movie) }

  has_many :votes, dependent: :destroy

  def self.top_ten(category)
    works_in_category = self.where(category: category).sort_by { |work| work.votes.count }
    if works_in_category.length > 10
      return works_in_category.reverse.first(10)
    else
      return works_in_category.reverse
    end
  end

  def self.spotlight
    vote_counts = self.all.map { |work| work.votes.count }
    max_vote_count = vote_counts.max
    winners = Work.all.select { |work| work.votes.count == max_vote_count }
    return winners.sample
  end
end
