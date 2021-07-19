# Copyright 2021 Google LLC. This software is provided as is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.

def main(request):
    request_json = request.get_json()
    if request.args and 'message' in request.args:
        return request.args.get('message')
    elif request_json and 'message' in request_json:
        return request_json['message']
    else:
        return f'Hello World!!1\n'
