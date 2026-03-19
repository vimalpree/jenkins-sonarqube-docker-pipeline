cat > test_app.sh << 'EOF'
#!/bin/bash
set -e
if grep -q "Hello from Jenkins" app.py; then
  echo "Basic validation passed"
else
  echo "Validation failed"
  exit 1
fi
EOF
chmod +x test_app.sh
