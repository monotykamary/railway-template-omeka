#!/usr/bin/env python3
import os,re,requests
b=os.environ['BASE_URL'].rstrip('/');pw=os.environ['ADMIN_PASSWORD'];home=requests.get(b+'/',timeout=30);assert home.status_code==200 and 'Omeka' in home.text
s=requests.Session();g=s.get(b+'/admin/users/login',timeout=30);token=re.search(r'name="csrf_token"[^>]*value="([^"]+)"',g.text);data={'username':'admin','password':pw};data.update({'csrf_token':token.group(1)} if token else {});login=s.post(g.url,data=data,allow_redirects=True,timeout=30);assert login.status_code==200 and ('/admin' in login.url and 'Log Out' in login.text),login.url
bad=requests.Session();g=bad.get(b+'/admin/users/login');token=re.search(r'name="csrf_token"[^>]*value="([^"]+)"',g.text);data={'username':'admin','password':'wrong-password'};data.update({'csrf_token':token.group(1)} if token else {});wrong=bad.post(g.url,data=data,allow_redirects=True);assert 'login' in wrong.url or 'Invalid' in wrong.text
print('Omeka smoke checks passed')
