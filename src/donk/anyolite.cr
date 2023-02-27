module Colorize
  @[Anyolite::ExcludeInstanceMethod("colorize")]
  module ObjectExtensions
  end
end

class RubyException < Exception
  @backtrace : Array(String)

  def initialize(rbref : Anyolite::RbRef)
    super(Anyolite.call_rb_method_of_object(rbref, :to_s, nil, cast_to: String))
    @backtrace = Anyolite.call_rb_method_of_object(rbref, :backtrace, nil, cast_to: Array(String))
  end

  def backtrace?
    @backtrace + (super || [] of String)
  end
end

module Funcs
  @@exception : Anyolite::RbClass? = nil

  @[Anyolite::Exclude]
  def self.setup
    @@exception = Anyolite::RbClass.get_from_ruby_name(Anyolite::RbRefTable.get_current_interpreter, "Exception")
  end

  def self.exception
    @@exception.not_nil!
  end
end

macro call_rb_block(block, args)
  %res = Anyolite.call_rb_block(
    {{ block }} {% unless args.empty? %},
    [{{ args.splat }}]{% end %})

  if Anyolite::RbCore.rb_obj_is_kind_of(
    Anyolite::RbRefTable.get_current_interpreter, %res, Funcs.exception) != 0
    raise RubyException.new(%res)
  end
  %res
end
