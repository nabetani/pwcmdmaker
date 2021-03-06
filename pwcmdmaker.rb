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

CMD_PLACE = "/usr/local/bin"

def acceptable?(cmd)
  /\A[a-zA-Z0-9_\-\.]+\z/===cmd
end

def password_command?(fn)
  return false unless File.split(fn)[0]==CMD_PLACE
  src = File.open( fn ){ |f| f.read(300) }
  src.include?(UUID)
end

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

  def self.make_cmd( pw1, pass )
    data = make_data(pw1)

    salt = OpenSSL::Random.random_bytes(20)
    enc = OpenSSL::Cipher.new("AES-256-CBC")
    enc.encrypt
    key_iv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(pass, salt, 2000, enc.key_len + enc.iv_len)
    key = key_iv[0, enc.key_len]
    iv = key_iv[enc.key_len, enc.iv_len]
    enc.key = key
    enc.iv = iv
    encrypted_data = enc.update(data) + enc.final
    
    <<~"SRC"
      #! #{RUBY}
      # frozen_string_literal: true

      # UUID:#{UUID}

      require 'openssl'

      def clean(s)
        s.bytes.select{ |e| (0x20..0x7f)===e.ord }.map(&:chr).join
      end

      dec = OpenSSL::Cipher.new("AES-256-CBC")
      dec.decrypt
      salt = #{salt.inspect}
      key_iv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(ARGV[0], salt, 2000, dec.key_len + dec.iv_len)
      dec.key = key_iv[0, dec.key_len]
      dec.iv = key_iv[dec.key_len, dec.iv_len]
      decrypted_data = dec.update(#{encrypted_data.inspect}) + dec.final
      pw = clean(decrypted_data)
      %x( printf "%s" "##{""}{pw}" | pbcopy )
    SRC
  end

  def self.run
    cmd, pw1, pw2 = ARGV[1,3]
    no_cmomand unless cmd
    invalid_command(cmd) unless acceptable?(cmd)
    no_pw1 unless pw1
    no_pw2 unless pw2
    path = File.join( CMD_PLACE, cmd )
    if File.exist?(path)
      path_exist(path)
    end
    src = make_cmd( pw1, pw2 )
    mode = File::Constants::CREAT | File::Constants::WRONLY | File::Constants::EXCL
    File.open( path, mode ){ |f| f.puts src }
    FileUtils.chmod( "+x", path )
  end

  def self.path_exist(path)
    puts "Failed to write, path exists: #{path}"
    exit
  end

  def self.invalid_command(cmd)
    puts "'#{cmd}' is not a valid command name"
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

module Remove
  def self.run
    cmd = ARGV[1]
    no_cmomand unless cmd
    invalid_command(cmd) unless acceptable?(cmd)
    path = File.join(CMD_PLACE, cmd)
    no_file(path) unless File.exist?(path)
    no_pw_cmd(path) unless password_command?(path)
    $stderr.puts( "remove #{path}?" )
    ans = $stdin.gets.downcase.strip
    if ans=="y"
      FileUtils.rm(path)
      puts "#{path} was deleted."
    end
  end

  def self.no_pw_cmd(path)
    puts "#{path} is not password command"
    exit
  end

  def self.no_file(path)
    puts "#{path} does not exist"
    exit
  end

  def self.invalid_command(cmd)
    puts "'#{cmd}' is not a valid command name"
    exit
  end

  def self.no_cmomand
    puts "no cmomand specified"
    exit
  end
end

module List
  def self.show(list)
    list.each do |i|
      puts( " "*4 + File.split(i)[1] )
    end
  end

  def self.run
    list = Dir.glob( File.join(CMD_PLACE, "*") ).sort.select{ |fn|
      password_command?(fn)
    }
    show list
  end
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

  def self.invalid_command
    puts "'#{ARGV[0]}' is not a valid command. See ruby #{__FILE__} help."
    exit
  end

  def self.main
    case ARGV[0]
    when "create"
      Create.run
    when "remove"
      Remove.run
    when "list"
      List.run
    when "version"
      version
    when "help", nil
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
