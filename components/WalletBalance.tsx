"use client";  
import { useEffect, useState } from 'react';  
import { supabase } from '@/lib/supabase';  
  
export default function WalletBalance() {  
  const [balance, setBalance] = useState<number | null>(null);  
  const [loading, setLoading] = useState(true);  
  
  useEffect(() => {  
    const fetchBalance = async () => {  
      const { data: { user } } = await supabase.auth.getUser();  
      if (user) {  
        const { data, error } = await supabase  
          .from('wallets')  
          .select('balance')  
          .eq('user_id', user.id)  
          .single();  
  
        if (data) setBalance(data.balance);  
      }  
      setLoading(false);  
    };  
  
    fetchBalance();  
  }, []);  
  
  return (  
    <div className="bg-slate-900 border border-slate-700 p-6 rounded-xl shadow-lg">  
      <h2 className="text-slate-400 text-sm uppercase tracking-wider">Available Balance</h2>  
      <div className="text-3xl font-bold text-yellow-500 mt-2">  
        {loading ? "Loading..." : `₦${balance?.toLocaleString() || "0.00"}`}  
      </div>  
    </div>  
  );  
}
