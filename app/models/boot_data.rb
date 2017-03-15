BootData = Struct.new(:user, :visitor) do
  def data
    serializer.new(user, scope: serializer_scope).as_json
  end

  private

  def serializer
    if user.restricted
      Restricted::UserSerializer
    else
      Full::UserSerializer
    end
  end

  def serializer_scope
    { memberships: memberships, visitors: visitors }.tap do |hash|
      hash.merge!(
        notifications:      notifications,
        unread:             unread,
        reader_cache:       readers
      ) if user.is_logged_in? && !user.restricted
    end
  end

  def memberships
    @memberships ||= user.memberships.includes(:user, :inviter, group: [{parent: :default_group_cover}, :default_group_cover]).order(created_at: :desc)
  end

  def notifications
    @notifications ||= NotificationCollection.new(user).notifications
  end

  def unread
    @unread ||= Queries::VisibleDiscussions.new(user: user).recent.unread.not_muted.sorted_by_latest_activity
  end

  def readers
    @readers ||= DiscussionReaderCache.new(user: user, discussions: unread)
  end

  def visitors
    @visitors ||= Array(visitor)
  end
end