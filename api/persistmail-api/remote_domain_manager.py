#!/usr/bin/env python3
"""
Remote Domain Management CLI for PersistMail
Usage: python remote_domain_manager.py [command] [options]
"""

import requests
import json
import argparse
import sys
from typing import Optional

class PersistMailClient:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url.rstrip('/')
        self.admin_prefix = "/api/v1/admin"
    
    def add_domain(self, domain: str, imap_host: str, imap_port: int = 993, 
                   is_premium: bool = False, is_mailcow: bool = True, 
                   credentials_key: str = None) -> dict:
        """Add a new domain remotely"""
        url = f"{self.base_url}{self.admin_prefix}/domains"
        payload = {
            "domain": domain,
            "imap_host": imap_host,
            "imap_port": imap_port,
            "credentials_key": credentials_key or "",
            "is_premium": is_premium,
            "is_mailcow_managed": is_mailcow
        }
        
        try:
            response = requests.post(url, json=payload)
            response.raise_for_status()
            return {"success": True, "data": response.json()}
        except requests.exceptions.RequestException as e:
            error_msg = str(e)
            if hasattr(e, 'response') and e.response is not None:
                try:
                    error_detail = e.response.json()
                    error_msg = f"{e} - {error_detail}"
                except:
                    error_msg = f"{e} - {e.response.text}"
            return {"success": False, "error": error_msg}
    
    def remove_domain(self, domain: str) -> dict:
        """Remove/deactivate a domain remotely"""
        url = f"{self.base_url}{self.admin_prefix}/domains/{domain}"
        
        try:
            response = requests.delete(url)
            response.raise_for_status()
            return {"success": True, "data": response.json()}
        except requests.exceptions.RequestException as e:
            return {"success": False, "error": str(e)}
    
    def list_domains(self) -> dict:
        """List all domains"""
        url = f"{self.base_url}{self.admin_prefix}/domains"
        
        try:
            response = requests.get(url)
            response.raise_for_status()
            return {"success": True, "data": response.json()}
        except requests.exceptions.RequestException as e:
            return {"success": False, "error": str(e)}
    
    def update_domain(self, domain: str, **kwargs) -> dict:
        """Update domain settings"""
        url = f"{self.base_url}{self.admin_prefix}/domains/{domain}"
        
        # Filter out None values
        payload = {k: v for k, v in kwargs.items() if v is not None}
        
        try:
            response = requests.put(url, json=payload)
            response.raise_for_status()
            return {"success": True, "data": response.json()}
        except requests.exceptions.RequestException as e:
            return {"success": False, "error": str(e)}

def print_result(result: dict):
    """Pretty print results"""
    if result["success"]:
        print("✅ Success!")
        if isinstance(result["data"], list):
            for item in result["data"]:
                status = "🟢" if item.get("is_active", True) else "🔴"
                premium = "💎" if item.get("is_premium", False) else "🆓"
                mailcow = "📧" if item.get("is_mailcow_managed", True) else "📪"
                domain_name = item.get("domain", "unknown")
                imap_info = ""
                if "imap_host" in item and "imap_port" in item:
                    imap_info = f" -> {item['imap_host']}:{item['imap_port']}"
                print(f"  {status} {premium} {mailcow} {domain_name}{imap_info}")
        else:
            print(f"  {json.dumps(result['data'], indent=2)}")
    else:
        print(f"❌ Error: {result['error']}")

def main():
    parser = argparse.ArgumentParser(description="Remote Domain Management for PersistMail")
    parser.add_argument("--server", default="http://localhost:8000", help="Server URL")
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Add domain command
    add_parser = subparsers.add_parser("add", help="Add a new domain")
    add_parser.add_argument("domain", help="Domain name")
    add_parser.add_argument("imap_host", help="IMAP server hostname")
    add_parser.add_argument("--port", type=int, default=993, help="IMAP port (default: 993)")
    add_parser.add_argument("--premium", action="store_true", help="Mark as premium domain")
    add_parser.add_argument("--no-mailcow", action="store_true", help="Don't use Mailcow management")
    add_parser.add_argument("--credentials-key", help="Credentials key for non-Mailcow domains")
    
    # Remove domain command
    remove_parser = subparsers.add_parser("remove", help="Remove/deactivate a domain")
    remove_parser.add_argument("domain", help="Domain name to remove")
    
    # List domains command
    list_parser = subparsers.add_parser("list", help="List all domains")
    
    # Update domain command
    update_parser = subparsers.add_parser("update", help="Update domain settings")
    update_parser.add_argument("domain", help="Domain name to update")
    update_parser.add_argument("--imap-host", help="New IMAP host")
    update_parser.add_argument("--port", type=int, help="New IMAP port")
    update_parser.add_argument("--premium", type=bool, help="Set premium status")
    update_parser.add_argument("--active", type=bool, help="Set active status")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    client = PersistMailClient(args.server)
    
    if args.command == "add":
        result = client.add_domain(
            args.domain, 
            args.imap_host, 
            args.port, 
            args.premium, 
            not args.no_mailcow,
            getattr(args, 'credentials_key', None)
        )
        print_result(result)
    
    elif args.command == "remove":
        result = client.remove_domain(args.domain)
        print_result(result)
    
    elif args.command == "list":
        result = client.list_domains()
        print_result(result)
    
    elif args.command == "update":
        kwargs = {}
        if args.imap_host:
            kwargs["imap_host"] = args.imap_host
        if args.port:
            kwargs["imap_port"] = args.port
        if args.premium is not None:
            kwargs["is_premium"] = args.premium
        if args.active is not None:
            kwargs["is_active"] = args.active
        
        result = client.update_domain(args.domain, **kwargs)
        print_result(result)

if __name__ == "__main__":
    main()
