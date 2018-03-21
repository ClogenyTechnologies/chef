#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "chef/provider/windows_task"
require 'pry'

describe Chef::Resource::WindowsTask, :windows_only do
  let(:task_name) { "chef-client" }
  let(:new_resource) { Chef::Resource::WindowsTask.new(task_name) }
  let(:windows_task_provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::WindowsTask.new(new_resource, run_context)
  end

  describe "action :create" do
    after { delete_task }
    context "when frequency and frequency_modifier are not passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        # Make sure MM/DD/YYYY is accepted
        new_resource.start_day "09/20/2017"
        new_resource
      end

      it "creates a scheduled task to run every 1 hr starting on 09/20/2017" do
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.application_name).to eq("chef-client")
        trigger_details = current_resource.task.trigger(0)
        expect(trigger_details[:start_year]).to eq("2017")
        expect(trigger_details[:start_month]).to eq("09")
        expect(trigger_details[:start_day]).to eq("20")
        expect(trigger_details[:minutes_interval]).to eq(60)
        expect(trigger_details[:trigger_type]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "frequency :minute" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :minute
        new_resource.frequency_modifier 15
        new_resource
      end

      it "creates a scheduled task that runs after every 15 minutes" do
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq("chef-client")
        expect(trigger_details[:minutes_interval]).to eq(15)
        expect(trigger_details[:trigger_type]).to eq(1)
        expect(current_resource.task.principals[:run_level]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "frequency :hourly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :hourly
        new_resource.frequency_modifier 3
        new_resource
      end

      it "creates a scheduled task that runs after every 3 hrs" do
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq("chef-client")
        expect(trigger_details[:minutes_interval]).to eq(180)
        expect(trigger_details[:trigger_type]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "frequency :daily" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :daily
        new_resource
      end

      it "creates a scheduled task to run daily" do
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq("chef-client")
        expect(trigger_details[:trigger_type]).to eq(2)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:type][:days_interval]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    # TODO : if frequency modifier is given it creates the monthly frequency with interval of 2 months not handled in code
    context "frequency :monthly" do
      # subject do
      #   new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      #   new_resource.command task_name
      #   new_resource.run_level :highest
      #   new_resource.frequency :monthly
      #   new_resource.frequency_modifier 2
      #   new_resource
      # end

      # it "creates a scheduled task to every 2 months" do
      #   call_for_create_action
      #   #loading current resource again to check new task is creted and it matches task parameters
      #   current_resource = call_for_load_current_resource
      #   expect(current_resource.exists).to eq(true)
      #   trigger_details = current_resource.task.trigger(0)
      #   expect(current_resource.task.application_name).to eq("chef-client")
      #   expect(trigger_details[:trigger_type]).to eq(2)
      #   expect(current_resource.task.principals[:run_level]).to eq(1)
      #   expect(trigger_details[:type][:days_interval]).to eq(1)

      #   # subject.run_action(:create)
      #   # task_details = windows_task_provider.send(:load_task_hash, task_name)
      #   # expect(task_details[:TaskName]).to eq("\\chef-client")
      #   # expect(task_details[:TaskToRun]).to eq("chef-client")
      #   # expect(task_details[:ScheduleType]).to eq("Monthly")
      #   # expect(task_details[:Months]).to eq("FEB, APR, JUN, AUG, OCT, DEC")
      #   # expect(task_details[:run_level]).to eq("HighestAvailable")
      # end

      # it "does not converge the resource if it is already converged" do
      #   subject.run_action(:create)
      #   subject.run_action(:create)
      #   expect(subject).not_to be_updated_by_last_action
      # end
    end

    context "frequency :once" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource
      end

      context "when start_time is not provided" do
        # TODO need to cover this argument error needs to be captured here

        # it "raises argument error" do
        #   expect { subject.run_action(:create) }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
        # end
      end

      context "when start_time is provided" do
        it "creates the scheduled task to run once at 5pm" do
          subject.start_time "17:00"
          call_for_create_action
          #loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq("chef-client")
          expect(trigger_details[:trigger_type]).to eq(1)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect("#{trigger_details[:start_hour]}:#{trigger_details[:start_minute]}" ).to eq(subject.start_time)
        end

        it "does not converge the resource if it is already converged" do
          subject.start_time "17:00"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end
    end

    context "frequency :onstart" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :onstart
        new_resource
      end

      it "creates the scheduled task to run at system start up" do
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq("chef-client")
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(8)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "frequency :weekly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :weekly
        new_resource
      end

      it "creates the scheduled task to run weekly" do
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq("chef-client")
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(3)
        expect(trigger_details[:type][:weeks_interval]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        # skip "This functionality needs to be handle"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      context "when days are provided" do
        it "creates the scheduled task to run on particular days" do
          subject.day "Mon, Fri"
          subject.frequency_modifier 2
          call_for_create_action
          #loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq("chef-client")
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(3)
          expect(trigger_details[:type][:weeks_interval]).to eq(2)
          expect(trigger_details[:type][:days_of_week]).to eq(34)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "Mon, Fri"
          subject.frequency_modifier 2
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      # context "when invalid day is passed" do
      #   it "raises error" do
      #     subject.day "abc"
      #     expect { subject.run_action(:create) }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
      #   end
      # end

      # context "when months are passed" do
      #   it "raises error that months are supported only when frequency=:monthly" do
      #     subject.months "Jan"
      #     expect { subject.run_action(:create) }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
      #   end
      # end

      context "frequency :on_logon" do
        subject do
          new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
          new_resource.command task_name
          new_resource.run_level :highest
          new_resource.frequency :on_logon
          new_resource
        end

        it "creates the scheduled task to on logon" do
          call_for_create_action
          #loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq("chef-client")
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(9)
        end

        it "does not converge the resource if it is already converged" do
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end
    end

    context "frequency :on_idle" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :on_idle
        new_resource
      end

      # context "when idle_time is not passed" do
      #   it "raises error" do
      #     expect { subject.run_action(:create) }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
      #   end
      # end

      context "when idle_time is passed" do
        it "creates the scheduled task to run when system is idle" do
          subject.idle_time 20
          call_for_create_action
          #loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq("chef-client")
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(6)
          expect(current_resource.task.settings[:idle_settings][:idle_duration]).to eq("PT20M")
          expect(current_resource.task.settings[:run_only_if_idle]).to eq(true)
        end

        it "does not converge the resource if it is already converged" do
          subject.idle_time 20
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end
    end

    context "when random_delay is passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource
      end

      it "sets the random_delay for frequency :minute" do
        subject.frequency :minute
        subject.random_delay "20"
        call_for_create_action
        #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq("chef-client")
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(1)
        expect(trigger_details[:random_minutes_interval]).to eq(20)
      end

      it "does not converge the resource if it is already converged" do
        subject.frequency :minute
        subject.random_delay "20"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "raises error if invalid random_delay is passed" do
        subject.frequency :minute
        subject.random_delay "abc"
        expect { subject.after_created }.to raise_error("Invalid value passed for `random_delay`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60').")
      end

      it "raises error if random_delay is passed with frequency on_idle" do
        subject.frequency :on_idle
        subject.random_delay "20"
        expect { subject.after_created }.to raise_error("`random_delay` property is supported only for frequency :once, :minute, :hourly, :daily, :weekly and :monthly")
      end
    end
  end


#     context "frequency :none" do
#       subject do
#         new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
#         new_resource.command task_name
#         new_resource.run_level :highest
#         new_resource.frequency :none
#         new_resource
#       end

#       it "creates the scheduled task to run on demand only" do
#         subject.run_action(:create)
#         task_details = windows_task_provider.send(:load_task_hash, task_name)

#         expect(task_details[:TaskName]).to eq("\\chef-client")
#         expect(task_details[:TaskToRun]).to eq("chef-client")
#         expect(task_details[:ScheduleType]).to eq("On demand only")
#         expect(task_details[:StartTime]).to eq("N/A")
#         expect(task_details[:StartDate]).to eq("N/A")
#         expect(task_details[:NextRunTime]).to eq("N/A")
#         expect(task_details[:none]).to eq(true)
#         expect(task_details[:run_level]).to eq("HighestAvailable")
#       end

#       it "does not converge the resource if it is already converged" do
#         subject.run_action(:create)
#         subject.run_action(:create)
#         expect(subject).not_to be_updated_by_last_action
#       end
#     end








  describe "Examples of idempotent checks for each frequency" do
    after { delete_task }
    context "For frequency :once" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.start_time "17:00"
        new_resource
      end

      it "create task by adding frequency_modifier as 1" do
        subject.frequency_modifier 1
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        # skip "This functionality needs to be handle"
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

#     context "For frequency :none" do
#       subject do
#         new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
#         new_resource.command task_name
#         new_resource.run_level :highest
#         new_resource.frequency :none
#         new_resource
#       end

#       it "create task by adding frequency_modifier as 1" do
#         subject.frequency_modifier 1
#         subject.run_action(:create)
#         subject.run_action(:create)
#         expect(subject).not_to be_updated_by_last_action
#       end

#       it "create task by adding frequency_modifier as 5" do
#         skip "This functionality needs to be handle"
#         subject.frequency_modifier 5
#         subject.run_action(:create)
#         subject.run_action(:create)
#         expect(subject).not_to be_updated_by_last_action
#       end
#     end

    context "For frequency :weekly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :weekly
        new_resource
      end

      it "create task by adding start_day" do
        subject.start_day "12/28/2018"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.frequency_modifier 3
        subject.random_delay "60"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :monthly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.start_time "17:00"
        new_resource
      end

      it "create task by adding frequency_modifier as 1" do
        subject.frequency_modifier 1
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        # skip "This functionality needs to be handle"
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :hourly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :hourly
        new_resource.frequency_modifier 5
        new_resource.random_delay "2400"
        new_resource
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :daily" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :daily
        new_resource.frequency_modifier 2
        new_resource.random_delay "2400"
        new_resource
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :on_logon" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.frequency :on_logon
        new_resource
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        # skip "This functionality needs to be handle"
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :onstart" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :onstart
        new_resource.frequency_modifier 20
        new_resource
      end

      it "create task by adding frequency_modifier as 20" do
        # skip "This functionality needs to be handle"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  describe "#after_created" do
    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.run_level :highest
      new_resource
    end

    context "when start_day is passed with frequency :onstart" do
      it "raises error" do
        subject.frequency :onstart
        subject.start_day "09/20/2017"
        expect { subject.after_created }.to raise_error("`start_day` property is not supported with frequency: onstart")
      end
    end

    context "when a non-system user is passed without password" do
      it "raises error" do
        subject.user "Administrator"
        subject.frequency :onstart
        expect { subject.after_created }.to raise_error(%q{Cannot specify a user other than the system users without specifying a password!. Valid passwordless users: 'NT AUTHORITY\SYSTEM', 'SYSTEM', 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE', 'BUILTIN\USERS', 'USERS'})
      end
    end

    context "when interactive_enabled is passed for a System user without password" do
      it "raises error" do
        subject.interactive_enabled true
        subject.frequency :onstart
        expect { subject.after_created }.to raise_error("Please provide the password when attempting to set interactive/non-interactive.")
      end
    end

    context "when frequency_modifier > 1439 is passed for frequency=:minute" do
      it "raises error" do
        subject.frequency_modifier 1450
        subject.frequency :minute
        expect { subject.after_created }.to raise_error("frequency_modifier value 1450 is invalid. Valid values for :minute frequency are 1 - 1439.")
      end
    end

    context "when invalid months are passed" do
      it "raises error" do
        subject.months "xyz"
        subject.frequency :monthly
        expect { subject.after_created }.to raise_error("months property invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC and *. Multiple values must be separated by a comma.")
      end
    end

    context "when idle_time > 999 is passed" do
      it "raises error" do
        subject.idle_time 1000
        subject.frequency :on_idle
        expect { subject.after_created }.to raise_error("idle_time value 1000 is invalid. Valid values for :on_idle frequency are 1 - 999.")
      end
    end

    context "when idle_time is passed for frequency=:monthly" do
      it "raises error" do
        subject.idle_time 300
        subject.frequency :monthly
        expect { subject.after_created }.to raise_error("idle_time property is only valid for tasks that run on_idle")
      end
    end
  end

  describe "action :delete" do
    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource
    end

#     it "deletes the task if it exists" do
#       subject.run_action(:create)
#       delete_task
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       expect(task_details).to eq(false)
#     end

    it "does not converge the resource if it is already converged" do
      subject.run_action(:create)
      subject.run_action(:delete)
      subject.run_action(:delete)
      expect(subject).not_to be_updated_by_last_action
    end
  end

#   describe "action :run" do
#     after { delete_task }

#     subject do
#       new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
#       new_resource.command "dir"
#       new_resource.run_level :highest
#       new_resource
#     end

#     it "runs the existing task" do
#       skip "Task status is returned as Ready instead of Running randomly"
#       subject.run_action(:create)
#       subject.run_action(:run)
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       expect(task_details[:Status]).to eq("Running")
#     end
#   end

#   describe "action :end", :volatile do
#     after { delete_task }

#     subject do
#       new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
#       new_resource.command "dir"
#       new_resource.run_level :highest
#       new_resource
#     end

#     it "ends the running task" do
#       subject.run_action(:create)
#       subject.run_action(:run)
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       subject.run_action(:end)
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       expect(task_details[:Status]).to eq("Ready")
#     end
#   end

#   describe "action :enable" do
#     after { delete_task }

#     subject do
#       new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
#       new_resource.command task_name
#       new_resource
#     end

#     it "enables the disabled task" do
#       subject.run_action(:create)
#       subject.run_action(:disable)
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       expect(task_details[:ScheduledTaskState]).to eq("Disabled")
#       subject.run_action(:enable)
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       expect(task_details[:ScheduledTaskState]).to eq("Enabled")
#     end
#   end

#   describe "action :disable" do
#     after { delete_task }

#     subject do
#       new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
#       new_resource.command task_name
#       new_resource
#     end

#     it "disables the task" do
#       subject.run_action(:create)
#       subject.run_action(:disable)
#       task_details = windows_task_provider.send(:load_task_hash, task_name)
#       expect(task_details[:ScheduledTaskState]).to eq("Disabled")
#     end
#   end

  def delete_task
    task_to_delete = Chef::Resource::WindowsTask.new(task_name, run_context)
    task_to_delete.run_action(:delete)
  end

  def call_for_create_action
    current_resource = call_for_load_current_resource
    expect(current_resource.exists).to eq(false)
    subject.run_action(:create)
    expect(subject).to be_updated_by_last_action
  end

  def call_for_load_current_resource
    windows_task_provider.send(:load_current_resource)
  end
end
