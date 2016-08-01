# name: discourse-hot_topics
# about: Adds ranking to topics
# version: 0.1
# author: Joe Buhlig joebuhlig.com
# url: https://github.com/danskdynamit/discourse-hot-topics

register_asset "stylesheets/upvote.scss"

enabled_site_setting :hot_topics_enabled

Discourse.top_menu_items.push(:hot)
Discourse.anonymous_top_menu_items.push(:hot)
Discourse.filters.push(:hot)
Discourse.anonymous_filters.push(:hot)

after_initialize do
	if SiteSetting.hot_topics_enabled

		require_dependency 'topic'
	    class ::Topic

			def hot_likes
				self.like_count
			end

			def hot_time
				((Time.now - self.created_at) / 1.hour)
			end

			def hot_gravity
				SiteSetting.hot_topics_gravity_rate
			end

			def hot_rating
				self.hot_likes / ((self.hot_time + 2) ** self.hot_gravity)
			end

			def hot_rating_custom
				self.custom_fields['upvote_hot']
			end

	    end

		require_dependency 'topic_view_serializer'
		class ::TopicViewSerializer
			attributes :hot_likes, :hot_time, :hot_gravity, :hot_rating

			def hot_likes
				object.topic.hot_likes
			end

			def hot_time
				object.topic.hot_time
			end

			def hot_gravity
				object.topic.hot_gravity
			end

			def hot_rating
				object.topic.hot_rating
			end

			def hot_rating_custom
				object.topic.custom_fields['upvote_hot']
			end

		end

		add_to_serializer(:topic_list_item, :hot_time) { object.hot_time }
		add_to_serializer(:topic_list_item, :hot_likes) { object.hot_likes }
		add_to_serializer(:topic_list_item, :hot_gravity) { object.hot_gravity }
		add_to_serializer(:topic_list_item, :hot_rating_custom) { object.hot_rating_custom }

		require_dependency 'list_controller'
		class ::ListController
		  def hot
		    list_opts = build_topic_list_options
		    list = TopicQuery.new(nil, list_opts).public_send("list_hot")
		    respond_with_list(list)
		  end
		end

		require_dependency 'topic_query'
		class ::TopicQuery
			SORTABLE_MAPPING["hot"] = "custom_fields.upvote_hot"

		  def list_hot
		  	result = create_list(:latest ,{}, latest_results({order: "hot"}))
		  end
		end

		module ::Jobs
      
      class UpvoteHot < Jobs::Scheduled
        every 30.minutes

        def execute(args)
          Topic.where(closed: false, archetype: 'regular').find_each do |topic|
            topic.custom_fields['upvote_hot'] = (topic.hot_rating * 1000000000).to_i
            topic.save
          end
        end
      end

    end

	Discourse::Application.routes.append do
      get "hot" => "list#hot"
    end

    TopicList.preloaded_custom_fields << "upvote_hot" if TopicList.respond_to? :preloaded_custom_fields

	end
end