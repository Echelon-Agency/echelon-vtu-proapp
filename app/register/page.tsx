import WalletBalance from '@/components/WalletBalance';

export default function DashboardPage() {
"use client";
import { useState } from 'react';
import { supabase } from '@/lib/supabase'; // Ensure you have your supabase client configured here

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
        <div className="p-8">
      <h1>Welcome to your Echelon Dashboard</h1>
      
      <WalletBalance />
      
    </div>
  );
}
    <form onSubmit={handleSignUp} className="p-8 space-y-4">
      <input type="text" placeholder="Full Name" onChange={(e) => setFormData({...formData, fullName: e.target.value})} required className="border p-2 w-full" />
      <input type="tel" placeholder="Phone Number" onChange={(e) => setFormData({...formData, phone: e.target.value})} required className="border p-2 w-full" />
      <input type="email" placeholder="Email" onChange={(e) => setFormData({...formData, email: e.target.value})} required className="border p-2 w-full" />
      <input type="password" placeholder="Password" onChange={(e) => setFormData({...formData, password: e.target.value})} required className="border p-2 w-full" />
      <button type="submit" disabled={loading} className="bg-blue-600 text-white p-2 w-full">
        {loading ? "Registering..." : "Sign Up"}
      </button>
    </form>
  );
        }
