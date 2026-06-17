"""User walkers"""

import time;
import from graph.user_nodes { User }

walker:priv CreateUser {
    has name: str,
        email: str,
        userType: str = "student";

    can run with Root entry {
        new_user = (root ++> User(
            id=f"user_{int(time.time())}",
            name=self.name,
            email=self.email,
            userType=self.userType,
            createdAt=str(int(time.time()))
        ))[0];

        report new_user;
    }
}


walker:priv GetUserProfile {
    can run with Root entry {
        users = [-->](?:User);
        report users[0] if users else None;
    }
}


walker:priv GetUserByEmail {
    can run with Root entry {
        users = [-->](?:User);
        report users[0] if users else None;
    }
}


walker:priv UpdateUserProfile {
    has name: str = None,
        userType: str = None,
        goals: list[str] = None,
        theme: str = None,
        accessibilityMode: bool = None;

    can run with Root entry {
        users = [-->](?:User);
        user_node = users[0] if users else None;

        if not user_node {
            report {"error": "User not found"};
            return;
        }

        if self.name is not None { user_node.name = self.name; }
        if self.userType is not None { user_node.userType = self.userType; }
        if self.goals is not None { user_node.goals = self.goals; }
        if self.theme is not None { user_node.theme = self.theme; }
        if self.accessibilityMode is not None { user_node.accessibilityMode = self.accessibilityMode; }

        report {"success": True, "user": user_node};
    }
}


walker:priv GetCurrentUser {
    can run with Root entry {
        try {
            users = [-->](?:User);
            user = users[0] if users else None;

            if not user {
                report {"authenticated": False, "isGuest": True};
                return;
            }

            report {
                "authenticated": True,
                "isGuest": False,
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "userType": user.userType if user.userType else "student",
                "goals": user.goals if user.goals else [],
                "theme": user.theme if user.theme else "light",
                "accessibilityMode": user.accessibilityMode if user.accessibilityMode else False
            };
        } except Exception as e {
            print(f"GetCurrentUser error: {e}");
            report {"authenticated": False, "isGuest": True};
        }
    }
}