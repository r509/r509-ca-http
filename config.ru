require './lib/r509/CertificateAuthority/Http/Server'
require 'r509/Middleware/Validity'

use R509::Middleware::Validity
run R509::CertificateAuthority::Http::Server
