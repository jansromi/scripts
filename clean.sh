#!/bin/bash

# SCRIPT FOR CLEANING REACT TEMPLATES CREATED WITH VITE

# Check if the "assets" folder exists, and delete it
if [ -d "src/assets" ]; then
    rm -r src/assets
    echo "Deleted 'assets' folder."
fi

# Delete all .css files from src
find ./src -type f -name "*.css" -exec rm {} +
echo "Deleted all .css files."

# If main.jsx exists, simplify it
if [ -e "src/main.jsx" ]; then
    echo "import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')).render(<App />)" > src/main.jsx
    echo "Simplified main.jsx"
fi

# If App.jsx exists, simplify it
if [ -e "src/App.jsx" ]; then
    echo "const App = () => (
  <div>
    <p>Hello world</p>
  </div>
)

export default App" > src/App.jsx
echo "Simplified App.jsx"
fi

echo "Cleanup complete."
