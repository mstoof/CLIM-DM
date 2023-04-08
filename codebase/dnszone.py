import re
import dns.message
import dns.query
import dns.resolver
import dns.update

class DnsUpdater:
    def __init__(self, domain_name, dns_server):
        '''
        Initialize the dns zone

        Arguments
        - zone: FQDN of the dns zone
        - nameserver -- IP address for the authorative
        '''
        self.domain_name = domain_name
        self.dns_server = dns_server


    def update_dns(self, ip_address):
        # Create a resolver object to query the DNS server
        resolver = dns.resolver.Resolver(configure=False)
        resolver.nameservers = [self.dns_server]
        # Look up the current IP address of the domain
        current_ip = str(resolver.resolve(self.domain_name, 'A')[0])
        # Create an update object to update the A record
        update = dns.update.Update(self.domain_name)
        update.replace('A', 300, ip_address)
        # Create a connection to the DNS server and send the update
        connection = dns.query.tcp(update, self.dns_server)
        # Check the response status
        if connection.rcode() != dns.rcode.NOERROR:
            raise Exception(f"DNS update failed with error code {connection.rcode()}")
        # Print a message indicating the update was successful
        print(f"DNS updated successfully: {self.domain_name} now points to {ip_address}")

if __name__ == '__main__':
    updater = DnsUpdater('example.com', 'ns1.example.com')
