task "assets:precompile" do
  # `jbundle install`
  # `jbundle install --vendor`
  require 'jbundler'
  config = JBundler::Config.new
  JBundler::LockDown.new( config ).lock_down
  JBundler::LockDown.new( config ).lock_down("--vendor")
end
