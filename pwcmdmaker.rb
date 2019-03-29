# frozen_string_literal: true

# version 0.1.1

=begin
usage: ruby $CMD_NAME$ <command> [<args>]

These are supported commands:

  create   create command with password
  remove   remove command
  list     list commands
  version  print version of this script

Use "ruby $CMD_NAME$ help <command>" for more information about a command.
=end

=begin create
usage: ruby $CMD_NAME$ create command-name pw1 pw2

Create command `command-name` in `/usr/local/bin/`.
Created command copies `pw1` to the clipboard.
To get `pw1`, you can run `command-name pw2`
=end

=begin remove
usage: ruby $CMD_NAME$ remove command-name

Remove command `command-name` from `/usr/local/bin/`
=end

=begin list
usage: ruby $CMD_NAME$ list command-name

List commands created by this command in `/usr/local/bin/`
=end

=begin version
usage: ruby $CMD_NAME$ version

This comand prints the version of this script.
=end

require 'openssl'
require 'fileutils'

RUBY = "/System/Library/Frameworks/Ruby.framework/Versions/2.3/usr/bin/ruby"
UUID = "0e1eb11a-4693-41cc-97e0-f4dc2b3279fa"

module Create
  def self.make_data(src)
    jamsrc = [*"\x0".."\x1f", *"\x80".."\xff"]
    len = Array.new(15){ |e| [e]*(2**e-1) }.flatten
    jams = Array.new(src.size){
      Array.new(len.sample){ jamsrc.sample }
    }
    src.chars.zip(jams).flatten.join
  end

  def self.clean(s)
    s.bytes.select{ |e| (0x20..0x7f)===e.ord }.map(&:chr).join
  end

  def self.make_cmd( pw1, pw2 )
    data = make_data(pw1)
    p data
    p clean(data)

    <<~"SRC"
      #! #{RUBY}
      # frozen_string_literal: true

      # UUID:#{UUID}

      require 'openssl'

      %x( printf "#{pw1}" | pbcopy )

    SRC
  end

  def self.run
    cmd, pw1, pw2 = ARGV[1,3]
    no_cmomand unless cmd
    invalid_command(cmd) unless /\A[a-zA-Z0-9_]+\z/===cmd
    no_pw1 unless pw1
    no_pw2 unless pw2
    src = make_cmd( pw1, pw2 )
    mode = File::Constants::CREAT | File::Constants::WRONLY | File::Constants::EXCL
    File.open( cmd, mode ){ |f| f.puts src }
    FileUtils.chmod( "+x", cmd )
  end

  def self.invalid_command(cmd)
    puts "Command name must consist of alphanumeric characters only"
    exit
  end

  def self.no_cmomand
    puts "no cmomand specified"
    exit
  end

  def self.no_pw1
    puts "no password1 specified"
    exit
  end

  def self.no_pw2
    puts "no password2 specified"
    exit
  end

end

def remove

end

def list

end

def version
  v = /\#\s*version\s*([\d\.]+)\s*[\r\n]/i.match(File.open( __FILE__, &:read ))[1]
  puts "#{File.split(__FILE__)[1]} version #{v}"
end

module Main
  def self.help
    src = File.open( __FILE__, &:read )
    key = case ARGV[1]
    when "create", "remove", "list", "version"
      "=begin " + ARGV[1]
    else
      "=begin"
    end
    b = src.index( key )+key.size+1
    len = src[b, src.size].index( "=end" )
    puts src[b,len].gsub( "$CMD_NAME$", File.split(__FILE__)[1] ) + "\n"
  end

  def self.extend
    puts( "'#{ARGV[0]}' is unknown command.\nRun 'ruby #{__FILE__} help' for usage." )
  end

  def self.main
    case ARGV[0]
    when "create"
      Create.run
    when "remove"
      remove
    when "list"
      list
    when "version"
      version
    when "help"
      help
    else
      invalid_command
    end
  end
end

Main.main

=begin

# 暗号化するデータ
data = "*secret data*"
# パスワード
pass = "**secret password**"
# salt
salt = OpenSSL::Random.random_bytes(8)

# 暗号化器を作成する
enc = OpenSSL::Cipher.new("AES-256-CBC")
enc.encrypt
# 鍵とIV(Initialize Vector)を PKCS#5 に従ってパスワードと salt から生成する
key_iv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(pass, salt, 2000, enc.key_len + enc.iv_len)
key = key_iv[0, enc.key_len]
iv = key_iv[enc.key_len, enc.iv_len]
# 鍵とIVを設定する
enc.key = key
enc.iv = iv

# 暗号化する
encrypted_data = ""
encrypted_data << enc.update(data)
encrypted_data << enc.final

p encrypted_data

# 復号化器を作成する
dec = OpenSSL::Cipher.new("AES-256-CBC")
dec.decrypt

# 鍵とIVを設定する
dec.key = key
dec.iv = iv

# 復号化する
decrypted_data = ""
decrypted_data << dec.update(encrypted_data)
decrypted_data << dec.final

p decrypted_data

=end
