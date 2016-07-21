# name: discourse-hot_topics
# about: Adds ranking to topics
# version: 0.1
# author: Joe Buhlig joebuhlig.com
# url: https://github.com/danskdynamit/discourse-hot-topics

register_asset "stylesheets/upvote.scss"

enabled_site_setting :hot_topics_enabled

after_initialize do
	if SiteSetting.hot_topics_enabled

		require_dependency 'topic'
	    class ::Topic

	      def hot
	      	likes = self.like_count
	      	time = ((Time.now - self.created_at) / 1.hour).round
	      	gravity = SiteSetting.hot_topics_gravity_rate
	        return likes / ((time + 2) ** gravity)
	      end 

	    end
		Discourse.top_menu_items.push(:hot)
		Discourse.filters.push(:hot)

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
            topic.custom_fields[:upvote_hot] = topic.hot
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