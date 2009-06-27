require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'tmpdir'

describe "Rerun functionally" do
  before do
    @dir = Dir.tmpdir + "/#{Time.now.to_i}"
    FileUtils.mkdir_p(@dir)
    @file = "#{@dir}/inc.txt"
    @app_file = "#{@dir}/foo.rb"
    touch_app_file
    launch_inc
  end

  def launch_inc
    fork do
      root = File.dirname(__FILE__) + "/.."
      exec("#{root}/bin/rerun -d #{@dir} ruby #{root}/inc.rb #{@file}")
    end
  end

  def read
    File.open(@file, "r") do |f|
      launched_at = f.gets.to_i
      count = f.gets.to_i
      [launched_at, count]
    end
  end

  def current_count
    launched_at, count = read
    count
  end

  def touch_app_file
    File.open(@app_file, "w") do |f|
      f.puts Time.now
    end
  end

  it "counts up" do
    sleep 1
    x = current_count
    sleep 0.5
    y = current_count
    y.should be > x
  end

  it "restarts when an app file is created" do
    sleep 2
    first_launched_at, count = read
    touch_app_file
    sleep 4
    second_launched_at, count = read

    second_launched_at.should be > first_launched_at
  end
  
end
