import { useEffect, useState } from "react";

function App() {
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch("http://localhost:5000/api")
      .then(res => res.json())
      .then(data => setMsg(data.message));
  }, []);

  return (
    <div style={{display:"flex",height:"100vh",alignItems:"center",justifyContent:"center"}}>
      <h1>{msg || "Loading..."}</h1>
    </div>
  );
}

export default App;
