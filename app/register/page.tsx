"use client";
import { useState } from 'react';
import { supabase } from '../../lib/supabase'; 
import WalletBalance from '../../components/WalletBalance'; 

export default function RegisterPage() {
  const [formData, setFormData] = useState({ email: '', password: '', fullName: '', phone: '' });
  const [loading, setLoading] = useState(false);

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const { data, error } = await supabase.auth.signUp({
      email: formData.email,
      password: formData.password,
      options: {
        data: {
          full_name: formData.fullName,
          phone: formData.phone,
        },
      },
    });

    if (error) {
      alert(error.message);
    } else {
      alert("Check your email for confirmation!");
    }
    setLoading(false);
  };

  return (
    <div className="p-8 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-6 text-yellow-500">Create Account</h1>
      
      <WalletBalance />

      <form onSubmit={handleSignUp} className="mt-6 space-y-4">
        <input 
          type="text" 
          placeholder="Full Name" 
          className="w-full p-3 bg-slate-900 border border-slate-700 rounded"
          onChange={(e) => setFormData({...formData, fullName: e.target.value})} 
        />
        <input 
          type="email" 
          placeholder="Email" 
          className="w-full p-3 bg-slate-900 border border-slate-700 rounded"
          onChange={(e) => setFormData({...formData, email: e.target.value})} 
        />
        <input 
          type="password" 
          placeholder="Password" 
          className="w-full p-3 bg-slate-900 border border-slate-700 rounded"
          onChange={(e) => setFormData({...formData, password: e.target.value})} 
        />
        <button 
          type="submit" 
          disabled={loading}
          className="w-full p-3 bg-yellow-600 hover:bg-yellow-500 text-black font-bold rounded transition"
        >
          {loading ? "Registering..." : "Sign Up"}
        </button>
      </form>
    </div>
  );
}
