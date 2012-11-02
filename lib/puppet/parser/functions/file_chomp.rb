module Puppet::Parser::Functions
  newfunction(:file_chomp, :type => :rvalue) do |args|
    raise(Puppet::ParseError, "file_chomp(): Wrong number of arguments given (#{args.size} instead of 1)") if args.size != 1
    File.open(args[0], "rb").read.chomp
  end
end