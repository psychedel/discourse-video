# frozen_string_literal: true

module DiscourseVideo
  class Video < ActiveRecord::Base
    ERRORED = "errored"
    READY = "ready"
    PENDING = "pending"
    WAITING = "waiting"

    belongs_to :user

    validates :state, inclusion: { in: %w(pending ready errored waiting),
                                   message: "%{value} is not a valid state" }

    def video_posts
      DiscourseVideo::VideoPost.where("video_info LIKE ?", "#{self.video_id}%")
    end

    def video_info
      "#{video_id}:#{state}"
    end

    def update_video_post_fields!
      video_posts.update_all(video_info: video_info)
    end

    def publish_change_to_clients!
      Post.find(video_posts.pluck(:post_id)).each do |post|
        post.publish_change_to_clients! :discourse_video_video_changed
      end
    end

    def video_chat_messages
      DiscourseVideo::VideoChatMessage.where("video_info LIKE ?", "#{self.video_id}%")
    end

    def update_video_chat_message_fields!
      video_chat_messages.update_all(video_info: video_info)
    end

    def publish_chat_message_change_to_clients!
      ChatMessage.find(video_chat_messages.pluck(:message_id)).each do |chat_message|
        ChatPublisher.publish_refresh!(chat_message.chat_channel, chat_message)
      end
    end
  end
end
