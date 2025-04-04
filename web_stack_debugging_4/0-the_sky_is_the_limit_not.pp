# Complete Nginx optimization with Apache conflict handling
# 1. Stops Apache if running
# 2. Disables Apache from auto-starting
# 3. Configures high-performance Nginx
# 4. Sets proper system limits

# Ensure required packages are installed
package { ['nginx', 'lsof']:
  ensure => installed,
}

# Stop and disable Apache if running
service { 'apache2':
  ensure => stopped,
  enable => false,
  before => File['/etc/nginx/nginx.conf'],
}

# Kill any remaining Apache processes
exec { 'kill-apache':
  command => '/usr/bin/pkill apache2 || true',
  onlyif  => '/usr/bin/pgrep apache2',
  before  => File['/etc/nginx/nginx.conf'],
}

# Create optimized Nginx configuration
file { '/etc/nginx/nginx.conf':
  ensure  => file,
  content => "
user www-data;
worker_processes auto;
pid /run/nginx.pid;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 30;
    keepalive_requests 100;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    server {
        listen 80 default_server reuseport;
        listen [::]:80 default_server reuseport;
        server_name localhost;

        location / {
            return 200 'Nginx optimized and running';
        }
    }
}
",
  require => Package['nginx'],
}

# Set system limits
exec { 'set-system-limits':
  command => '/bin/echo "www-data soft nofile 65535" >> /etc/security/limits.conf && \
             /bin/echo "www-data hard nofile 65535" >> /etc/security/limits.conf && \
             /bin/echo "fs.file-max = 65535" >> /etc/sysctl.conf && \
             /sbin/sysctl -p',
  unless  => '/bin/grep -q "www-data soft nofile 65535" /etc/security/limits.conf',
}

# Ensure Nginx service is running
service { 'nginx':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  subscribe  => [File['/etc/nginx/nginx.conf'], Exec['set-system-limits']],
}
