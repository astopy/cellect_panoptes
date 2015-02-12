require 'active_record'

module Cellect
  module Server
    module Adapters
      class Workflow < ActiveRecord::Base
        has_many :subject_sets
      end

      class SubjectSet < ActiveRecord::Base
        belongs_to :workflow
        has_many :set_member_subjects
      end

      class SetMemberSubject < ActiveRecord::Base
        belongs_to :subject_set
      end

      class UserSeenSubject < ActiveRecord::Base
      end
      
      class Panoptes < Default
        def initialize
          ActiveRecord::Base.establish_connection(**connection_options)
        end

        def workflow_list(*names)
          Workflow.select(:id, :prioritized, :pairwise, :grouped)
            .where(id: names)
            .map do |row|
            {
              'id' => row.id,
              'name' => row.id,
              'prioritized' => row.prioritized,
              'pairwise' => row.pairwise,
              'grouped' => row.grouped
            }
          end
        end

        def load_data_for(workflow_name)
          SetMemberSubject.joins(:subject_set)
            .where(subject_sets: { workflow_id: workflow_name },
                   state: 0)
            .select(:subject_id, :priority, :subject_set_id)
            .map do |row|
            {
              'id' => row.subject_id,
              'priority' => row.priority,
              'group_id' => row.subject_set_id
            }
          end
        end

        def load_user(workflow_name, user_id)
          UserSeenSubject.where(workflow_id: workflow_name,
                                user_id: user_id)
            .select(:subject_ids)
            .map do |row|
            row.subject_ids
          end
        end

        def connection_options
          {
            adapter: "postgresql",
            host: ENV.fetch('PG_HOST', '127.0.0.1'),
            port: ENV.fetch('PG_PORT', '5432'),
            dbname: ENV.fetch('PG_DB', 'cellect'),
            user: ENV.fetch('PG_USER', 'cellect'),
            password: ENV.fetch('PG_PASS', '')
          }
        end
      end
    end
  end
end
