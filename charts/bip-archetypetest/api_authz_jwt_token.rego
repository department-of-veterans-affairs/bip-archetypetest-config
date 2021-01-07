package bip.http.authz

import input

########################################################
# BIP Framework sets fields/keys under "input" field
# passed for the OPA request body (req_body)
# 1) input.auth
#	 - Represents the token for an authentication
#		request or for an authenticated principal
# 2) input.method
#	 - Represents the name of the HTTP method
# 3) input.path
#	 - Represents the path of the HTTP Request URI
# 4) input.headers
#	 - Represents the request header name value pairs
# 5) input.parameters
#	 - Represents the request parameter name value pairs
#########################################################

# disallow access to all by default
default allow = false

# decode JWT token to read the payload
token = {"payload": payload} {
  [_, encoded] := split(input.headers.authorization, " ")
  [header, payload, signature] := io.jwt.decode(encoded)
}

# Allow authenticated users to invoke methods.
allow {
  input.method == "POST"
  input.path[0] == "api"
  input.auth.principal.assuranceLevel == 2 	# assuranceLevel check for valid users
  token.payload.iss == "Vets.gov" 			# Ensure the issuer claim is the expected value
}

# Allow authenticated users to invoke methods.
allow {
  input.method == "POST"
  input.path[0] == "api"
  input.auth.principal.assuranceLevel == 1 	# assuranceLevel check for valid users
  token.payload.iss == "Vets.gov" 			# Ensure the issuer claim is the expected value
}

# Allow authenticated users to invoke methods.
allow {
  input.method  == "GET"
  input.path[0] == "api"
  input.auth.principal.assuranceLevel == 1 	# assuranceLevel check for valid users
  token.payload.iss == "Vets.gov" 			# Ensure the issuer claim is the expected value
}

# Allow authenticated users to invoke methods.
allow {
  input.method  == "GET"
  input.path[0] == "api"
  input.auth.principal.assuranceLevel == 2 	# assuranceLevel check for valid users
  token.payload.iss == "Vets.gov" 			# Ensure the issuer claim is the expected value
}

# Allow admin users to invoke any methods.
admin {
  input.auth.principal.assuranceLevel == 3 	# fake assuranceLevel just to demonstrate
}

admin {
  input.auth.principal.assuranceLevel == 7 	# fake assuranceLevel just to demonstrate
}

# user-role assignments
#user_roles := {
#    "JANE DOE": ["engineering", "webdev"],
#    "JANE DOE": ["hr"]
#}

# role-permissions assignments
#role_permissions := {
#    "engineering": [{"action": "read",  "object": "server123"}],
#    "webdev":      [{"action": "read",  "object": "server123"},
#                    {"action": "write", "object": "server123"}],
#    "hr":          [{"action": "read",  "object": "database456"}]
#}

# logic that implements RBAC.
# allow {
#    # lookup the list of roles for the user
#    roles := user_roles[input.auth.principal.user]
#    # for each role in that list
#    r := roles[_]
#    # lookup the permissions list for role r
#    permissions := role_permissions[r]
#    # for each permission
#    p := permissions[_]
#    # check if the permission granted to r matches the user's request
#    p == {"action": input.action, "object": input.object}
#}