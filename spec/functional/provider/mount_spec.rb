#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'spec_helper'
require 'chef/mixin/shell_out'

describe Chef::Provider::Mount::Mount do
  # Order the tests for proper cleanup and execution
  RSpec.configure do |config|
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description }
    end
  end

  # Load ohai only once
  ohai = Ohai::System.new
  ohai.all_plugins

  include Chef::Mixin::ShellOut
  before(:each) do
    shell_out!("mkfs -q /dev/ram1 512")
    shell_out!("mkdir -p /tmp/foo")
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    
    @new_resource = Chef::Resource::Mount.new('/tmp/foo')
    @new_resource.device      "/dev/ram1"
    @new_resource.name        "/tmp/foo"
    @new_resource.fstype      "tmpfs"
    
    providerClass = Chef::Platform.find_provider(ohai[:platform], ohai[:version], @new_resource)
    @provider = providerClass.new(@new_resource, @run_context)
  end

  describe "testcase 1: when the target state is a mounted filesystem" do
    it "should mount the filesystem if it isn't mounted" do
      @provider.load_current_resource
      @provider.current_resource.enabled.should be_false
      @provider.current_resource.mounted.should be_false
      @provider.should_receive(:mount_fs).and_call_original
      @provider.run_action(:mount)
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_true
    end
  end

  describe "testcase 2: when the target state is a mounted filesystem" do
    it "should not mount the filesystem if it is mounted" do
      @provider.should_not_receive(:mount_fs)
      @provider.run_action(:mount)
    end
  end

  describe "testcase 3: when the filesystem should be remounted and the resource supports remounting" do
    before do
      @new_resource.supports[:remount] = true
    end
    
    it "should remount the filesystem if it is mounted" do
      @provider.should_receive(:remount_fs).and_call_original
      @provider.run_action(:remount)
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_true
    end
  end

  describe "testcase 4: when the target state is a unmounted filesystem" do
    it "should umount the filesystem if it is mounted" do
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_true
      @provider.should_receive(:umount_fs).and_call_original
      @provider.run_action(:umount)
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_false
    end
  end

  describe "testcase 5: when the target state is a unmounted filesystem" do
    it "should not umount the filesystem if it is not mounted" do
      @provider.should_not_receive(:umount_fs)
      @provider.run_action(:umount)
    end
  end

  describe "testcase 6: when the resource supports remounting" do
    before do
      @new_resource.supports[:remount] = true
    end
    it "should not remount the filesystem if it is not mounted" do
      @provider.should_not_receive(:remount_fs)
      @provider.run_action(:remount)
    end
  end

end

