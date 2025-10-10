class TagsController < ApplicationController
  def all
    tags_with_counts = Post.all.map do |post|
      post.tag_list.map { |tag| [tag, post.updated_at] }
    end.flatten(1)
    tag_hash = tags_with_counts.group_by { |t| t[0] }
    tags = tag_hash.map do |tag, arr|
      { name: tag, count: arr.size, recent: arr.map { |a| a[1] }.max }
    end
    sorted_by_recent = tags.sort_by { |t| -t[:recent].to_i }
    sorted_by_count = tags.sort_by { |t| -t[:count] }
    @recent_tags = sorted_by_recent.first(20)
    @most_used_tags = sorted_by_count.first(20)
    @all_tags = tags.sort_by { |t| t[:name].downcase }
  end
end
