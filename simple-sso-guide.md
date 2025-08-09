# Simple SSO Integration Guide

## 🎯 **How It Works**

1. User clicks your app in our dashboard
2. We generate a JWT token with user info
3. User gets redirected to `http://localhost:3001/auth/sso?token=JWT_HERE`
4. Your app validates the JWT and logs the user in
5. Done!

## 🔑 **Your Credentials**

### **JWT Secret:**
```bash
SSO_JWT_SECRET=45ebba4385dba30e7c60a589f780b6b19b1bf89dc04091fc138410282791114f
```

### **Platform URL:**
```bash
PLATFORM_URL=http://localhost:3000
```

### **What You Give Us:**
Your app URL where we should redirect users:
```
http://localhost:3001/auth/sso
```

## 🛠️ **Implementation**

### **Create `/auth/sso` endpoint:**

```javascript
const jwt = require('jsonwebtoken');

app.post('/auth/sso', (req, res) => {
  const token = req.query.token;
  
  try {
    // Validate JWT with our secret
    const payload = jwt.verify(token, '45ebba4385dba30e7c60a589f780b6b19b1bf89dc04091fc138410282791114f');
    
    // Get user info from token
    const { userId, email, name, role } = payload;
    
    // Create or update user in your database
    let user = await User.findOne({ platformUserId: userId });
    if (!user) {
      user = await User.create({
        platformUserId: userId,
        email,
        name,
        role
      });
    }
    
    // Log user in (create session)
    req.session.userId = user.id;
    
    // Redirect to your app
    res.redirect('/dashboard');
    
  } catch (error) {
    res.status(401).send('Invalid token');
  }
});
```

## 🔑 **JWT Token Contains:**

```json
{
  "userId": "platform-user-id",
  "email": "user@example.com", 
  "name": "John Doe",
  "role": "member",
  "expiresAt": 1704067200000
}
```

## ✅ **That's It!**

**Simple Setup:**
1. You tell us your app URL: `http://localhost:3001/auth/sso`
2. We give you the JWT secret: `45ebba4385dba30e7c60a589f780b6b19b1bf89dc04091fc138410282791114f`
3. User clicks your app → We redirect them to your URL with JWT token
4. You verify JWT and log them in
5. Done!

No app slugs, no API keys, no complicated stuff!
