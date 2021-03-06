require "test_helper"

describe User do
  describe "validations" do
    before do
      @user = User.new(username: "username")
    end

    it "is valid when username is present" do
      result = @user.valid?
      result.must_equal true
    end

    it "is not valid when username is absent" do
      @user.username = nil
      result = @user.valid?
      result.must_equal false
    end
  end

  describe "relations" do
    it "has votes" do
      user = users(:bender)
      user.votes.must_include votes(:one)
    end

    it "can add votes" do
      user = User.new(username: "newuser")
      vote = Vote.new(user_id: user.id, work_id: Work.last.id)
      user.votes << vote
      user.votes.must_include vote
    end
  end

  describe "j_index" do
    before do
      @user1 = User.create(username: "newuser")
      @user2 = User.create(username: "othernewuser")
    end
    it "will return 1 for two users whose upvote history is identical" do
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id)
          Vote.create(work_id: work.id, user_id: @user2.id)
        end
      end

      expect @user1.j_index(@user2).must_equal 1
    end

    it "will return a number between 0 and 1 for users with some common upvotes" do
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id)
        end
      end

      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user2.id)
      end

      expect @user1.j_index(@user2).must_be :>, 0
      expect @user1.j_index(@user2).must_be :<, 1
    end

    it "will return 0 for two users who have no common upvotes" do
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id)
        end
      end

      Work.all.each_with_index do |work, index|
        if index % 2 != 0
          Vote.create(work_id: work.id, user_id: @user2.id)
        end
      end

      expect @user1.j_index(@user2).must_equal 0
    end

    it "will return -1 for two users where one user's downvotes are identical to another user's upvotes" do
      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user1.id)
        Vote.create(work_id: work.id, user_id: @user2.id, value: -1)
      end

      expect @user1.j_index(@user2).must_equal -1
    end

    it "will return a number between 0 and -1 for users who disagree more than agree" do
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id, value: -1)
        else
          Vote.create(work_id: work.id, user_id: @user1.id)
        end
      end

      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user2.id, value: 1)
      end

      expect @user1.j_index(@user2).must_be :<, 0
      expect @user1.j_index(@user2).must_be :>, -1
    end

    it "will return a number between 0 and -1 for users who agree more than disagree" do
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id, value: -1)
        else
          Vote.create(work_id: work.id, user_id: @user1.id)
        end
      end

      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user2.id, value: -1)
      end

      expect @user1.j_index(@user2).must_be :>, 0
      expect @user1.j_index(@user2).must_be :<, 1
    end

    it "will return 1 for two users who have identical downvote history" do
      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user1.id, value: -1)
        Vote.create(work_id: work.id, user_id: @user2.id, value: -1)
      end

      expect @user1.j_index(@user2).must_equal 1
    end

    it "will return a number between 0 and 1 for users with some common downvotes" do
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id, value: -1)
        end
      end

      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user2.id, value: -1)
      end

      expect @user1.j_index(@user2).must_be :>, 0
      expect @user1.j_index(@user2).must_be :<, 1
    end

    it "will return 0 if user in argument has no upvotes or downvotes" do
      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user1.id)
      end

      expect @user1.j_index(@user2).must_equal 0
    end

    it "will return 0 if user the method is called on has no upvotes or downvotes" do
      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user2.id)
      end

      expect @user1.j_index(@user2).must_equal 0
    end
  end

  describe "get_similar_users" do
    it "will return a sorted list of similar users" do
      @user1 = User.create(username: "newuser")
      @user2 = User.create(username: "othernewuser")
      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user1.id)
        Vote.create(work_id: work.id, user_id: @user2.id)
      end

      result = @user1.get_similar_users
      # all likes are common, so @user2 should be first on the list
      expect(result[0]).must_equal @user2

      result.each_with_index do |user, index|
        if index != 0
          expect(@user1.j_index(user)).must_be :<=, @user1.j_index(result[index - 1])
        end
      end
    end

    it "will return an empty array if no other users" do
      User.destroy_all
      @user1 = User.create(username: "newuser")
      result = @user1.get_similar_users
      expect(result).must_be_empty
    end
  end

  describe "get_recommendations" do
    it "will return a list of works, sorted by the average j_index of users who voted for them" do
      @user1 = User.create(username: "newuser")
      Work.all.each_with_index do |work, index|
        if index % 2 == 0
          Vote.create(work_id: work.id, user_id: @user1.id)
        end
      end

      result = @user1.get_recommendations

      j_index_averages = result.map do |work_id|
        work = Work.find(work_id)
        work_users = work.votes.map { |vote| User.find(vote.user_id) }
        j_average = (work_users.reduce(0) { |total, user| total += @user1.j_index(user) }) / work_users.length
      end

      j_index_averages.each_with_index do |average, index|
        if index != 0
          expect(average).must_be :<=, @user1.j_index(j_index_averages[index - 1])
        end
      end
    end

    it "will return an empty array if the user has upvoted all works in the database " do
      @user1 = User.create(username: "newuser")
      Work.all.each_with_index do |work, index|
        Vote.create(work_id: work.id, user_id: @user1.id)
      end

      expect(@user1.get_recommendations).must_be_empty
    end
  end
end
