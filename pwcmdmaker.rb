# frozen_string_literal: true

=begin
usage: ruby $CMD_NAME$ <command> [<args>]

These are supported commands:

  create   create command with password
  remove   remove command
  list     list commands

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

require 'openssl'

def create

end

def remove

end

def list

end

def help
  src = File.open( __FILE__, &:read )
  key = case ARGV[1]
  when "create", "remove", "list"
    "=begin " + ARGV[1]
  else
    "=begin"
  end
  b = src.index( key )+key.size+1
  len = src[b, src.size].index( "=end" )
  puts src[b,len].gsub( "$CMD_NAME$", File.split(__FILE__)[1] ) + "\n"
end

def invalid_command
  puts( "'#{ARGV[0]}' is unknown command.\nRun 'ruby #{__FILE__} help' for usage." )
end

def main
  case ARGV[0]
  when "create"
    create
  when "remove"
    remove
  when "list"
    list
  when "help"
    help
  else
    invalid_command
  end
end

main

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
