class iteego {

  define line( $file, $line, $ensure = 'present' ) {
    case $ensure {
      default: {
        err ( "unknown ensure value ${ensure}" )
      }
      present: {
        exec { "/bin/echo '${line}' >> '${file}'":
          unless => "/bin/grep -qFx '${line}' '${file}'",
        }
      }    
      absent: {
        exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
          onlyif => "/bin/grep -qFx '${line}' '${file}'",
        }
      }
    }
  }
  

  define base-ubuntu-server {
		# Packages  
		package {
			"ntp":
				ensure => present,
				require => Exec["aptgetupdate"];
			"unzip":
				ensure => present,
				require => Exec["aptgetupdate"];
			"openjdk-7-jdk":
				ensure => present,
				require => Exec["aptgetupdate"];
			"ec2-api-tools":
				ensure => present,
				require => Exec["aptgetupdate"];
			"postfix":
				ensure => present,
				require => Exec["aptgetupdate"];
			"groovy":
				ensure => present,
				require => Exec["aptgetupdate"];
			"iftop":
				ensure => present,
				require => Exec["aptgetupdate"];
			"htop":
				ensure => present,
				require => Exec["aptgetupdate"];
			"iotop":
				ensure => present,
				require => Exec["aptgetupdate"];
			"nethogs":
				ensure => present,
				require => Exec["aptgetupdate"];
			"ncurses-term":
				ensure => present,
				require => Exec["aptgetupdate"];
			"inotify-tools":
				ensure => present,
				require => Exec["aptgetupdate"];
			"timelimit":
			  ensure => present,
				require => Exec["aptgetupdate"];
			'xfsprogs':
				ensure => present,
				require => Exec['aptgetupdate'];
			'consolekit':
				ensure => absent,
				require => Exec['aptgetupdate'];
		}
		
    # kernel settings
    file { "sysctl.conf":
			path    => '/etc/sysctl.conf',
			ensure  => present,
			mode    => 0644,
			content => template('iteego/etc/sysctl.conf.erb'),
    }

    # set the time zone
    file { "/etc/timezone":
			content => template('iteego/etc/timezone.erb'),
    }
    
    # execute on the new time zone
		exec { "dpkg-reconfigure -f noninteractive tzdata":
			path   => ["/bin", "/usr/bin", "/usr/sbin"],
			subscribe   => File["/etc/timezone"],
			refreshonly => true,
		}

    # remove popularity contest cron job
    file { "/etc/cron.daily/popularity-contest":
			ensure  => absent,
    }

    # write our git config
    $gitconfig = "[user]
                    name = $::fqdn
                    email = admin@iteego.com
                 "

    file { "/root/.gitconfig":
      ensure  => present,
      mode    => 0600,
      content => $gitconfig,
    }

    $cron_mailto="admin@iteego.com"
    $cron_shell="/bin/bash"

    cron { "puppet-remove-reports":
      ensure  => present,
      command => "rm -fR /var/lib/puppet/reports/$::fqdn/*",
      user    => 'root',
      minute  => '*',
      environment => [
        "SHELL=$cron_shell",
        "MAILTO=$cron_mailto",
      ],
    }

    # Add our server key to the list of authorized login keys
    exec { "cat /etc/puppet/bootstrap/keys/id_rsa.pub >>/root/.ssh/authorized_keys":
      path   => ["/bin", "/usr/bin", "/usr/sbin"],
      unless => '/bin/grep -q "$(cat /etc/puppet/bootstrap/keys/id_rsa.pub)" /root/.ssh/authorized_keys',
    }

    # Add functionality to watch files for changes and commit them to our state
    file { "/etc/watch_files":
      ensure  => present,
      mode    => 0600,
      content => template("watch_files/$::hostname.erb"),
    }

    # Make sure our watcher daemon is running
    exec { 'watch_files':
      command => 'nohup watch_files.sh /etc/watch_files &>>/var/log/puppet/puppet.log &',
      logoutput => true,
      path   => ['/bin', '/usr/bin', '/usr/sbin', '/etc/puppet/files/bin'],
      onlyif => [
                  '[ -e /etc/watch_files ]',
                  '[ ! $(pgrep watch_files.sh) ]'
                ],
    }

    user { 'iteego':
      ensure => present,
      shell => '/bin/bash',
      managehome => true,
      home => '/home/iteego',
      groups => 'admin',
      password => '$6$r0Vj7Qgb$s8tJji0wc8lOKhkwscolkwlwTwErkh0N5fdJS8P6t/vB.lhq6EO.AjA8upv0F7HYH8VsDSFNl5qZdpZ1bDNFL.',
    }
    
    exec { 'make_swap':
      unless => "grep -q -E '^/mnt/swp' /proc/swaps",
      path   => ['/bin', '/usr/bin', '/usr/sbin', '/etc/puppet/files/bin'],
      logoutput => true,
      command => 'nohup nice /etc/puppet/modules/iteego/files/bin/make_swap.sh',
    }
      
  }

  define capture-ec2-singleton-metadata {
    $ip_address_file = "/etc/puppet/state/$::iteego_environment/$::hostname/meta-data/local-ipv4"
    $public_hostname_file = "/etc/puppet/state/$::iteego_environment/$::hostname/meta-data/public-hostname"
		exec { 'capture-ec2-meta-data.sh singleton':
			path   => ['/bin', '/usr/bin', '/usr/sbin', '/etc/puppet/files/bin'],
			onlyif => "[ ! -e $ip_address_file ] || [ $::ipaddress_eth0 != $(cat $ip_address_file) ] || [ ! -e $public_hostname_file ] || [ $(curl http://169.254.169.254/latest/meta-data/public-hostname) != $(cat $public_hostname_file) ]",
			logoutput => true,
		}
  }

  define capture-ec2-instance-metadata {
    $ip_address_file = "/etc/puppet/state/$::iteego_environment/$::hostname/$::ec2_instance_id/meta-data/local-ipv4"
    $public_hostname_file = "/etc/puppet/state/$::iteego_environment/$::hostname/$::ec2_instance_id/meta-data/public-hostname"
		exec { 'capture-ec2-meta-data.sh':
			path   => ['/bin', '/usr/bin', '/usr/sbin', '/etc/puppet/files/bin'],
			onlyif => "[ ! -e $ip_address_file ] || [ $::ipaddress_eth0 != $(cat $ip_address_file) ] || [ ! -e $public_hostname_file ] || [ $(curl http://169.254.169.254/latest/meta-data/public-hostname) != $(cat $public_hostname_file) ]",
			logoutput => true,
		}
  }

  define deployment-target {
    # check to see if environment commit is different from actual commit
    # if different, run deployment script
    # deployment script will, if all worked, update this instance's commit


    # make deploy.sh script
    # that runs environment/node deploy script based on desired commit
    # and if successful,

    file { '/opt':
		  ensure  => directory,
		  mode    => 0755,
    }

    file { '/opt/service':
		  ensure  => directory,
		  mode    => 0755,
    }

    file { '/opt/service/version':
		  ensure  => directory,
		  mode    => 0755,
    }

    file { '/etc/init.d/service':
			force   => true,
			replace => true,
			ensure  => link,
      target => "/etc/puppet/modules/iteego/scripts/$::hostname/etc/init.d/service.sh",
    }

		service { 'service':
			enable => true,
			ensure => running,
			require => File['/etc/init.d/service'],
		}

    # Call deploy.sh if our commit differs from the environment commit
    $env_commit_file="/etc/puppet/state/$::iteego_environment/commit"
    $node_commit_file="/etc/puppet/state/$::iteego_environment/$::hostname/commit"
    $instance_commit_file="/etc/puppet/state/$::iteego_environment/$::hostname/$::ec2_instance_id/commit"

    exec { "/etc/puppet/files/bin/deploy.sh":
      path   => ["/bin", "/usr/bin", "/usr/sbin"],
      logoutput => true,
      onlyif => "[ -e $env_commit_file ] && ( \
                 ( [ ! -e $node_commit_file ] && [ ! -e $instance_commit_file ] ) || \
                 ( [ -e $node_commit_file ] && [ $(cat $env_commit_file) != $(cat $node_commit_file) ] ) || \
                 ( [ -e $instance_commit_file ] && [ $(cat $env_commit_file) != $(cat $instance_commit_file) ] ) \
               )"
    }

  }

}
