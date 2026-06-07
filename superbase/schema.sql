-- Migration: 20260607100657

-- 1. ENUM Types
DROP TYPE IF EXISTS public.transaction_status CASCADE;
CREATE TYPE public.transaction_status AS ENUM ('pending', 'success', 'failed');

DROP TYPE IF EXISTS public.transaction_type CASCADE;
CREATE TYPE public.transaction_type AS ENUM ('data', 'airtime', 'wallet_credit', 'wallet_debit');

-- 2. Core Tables

-- user_profiles (intermediary for auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL DEFAULT '',
  phone TEXT DEFAULT '',
  referral_code TEXT DEFAULT '',
  avatar_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- wallets (one per user)
CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  bonus_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);

-- transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reference TEXT NOT NULL UNIQUE,
  tx_type public.transaction_type NOT NULL DEFAULT 'data'::public.transaction_type,
  network TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  plan TEXT DEFAULT '',
  amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  status public.transaction_status NOT NULL DEFAULT 'pending'::public.transaction_status,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.transactions(status);

-- 4. Functions

-- Auto-create user_profile + wallet on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, phone, referral_code, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'referral_code', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.wallets (user_id, balance, bonus_balance)
  VALUES (NEW.id, 0.00, 0.00)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

-- updated_at auto-update function
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Debit wallet function
CREATE OR REPLACE FUNCTION public.debit_wallet(p_user_id UUID, p_amount NUMERIC)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_balance NUMERIC;
BEGIN
  SELECT balance INTO v_balance FROM public.wallets WHERE user_id = p_user_id FOR UPDATE;
  IF v_balance IS NULL OR v_balance < p_amount THEN
    RETURN FALSE;
  END IF;
  UPDATE public.wallets SET balance = balance - p_amount, updated_at = CURRENT_TIMESTAMP WHERE user_id = p_user_id;
  RETURN TRUE;
END;
$$;

-- Credit wallet function
CREATE OR REPLACE FUNCTION public.credit_wallet(p_user_id UUID, p_amount NUMERIC)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.wallets SET balance = balance + p_amount, updated_at = CURRENT_TIMESTAMP WHERE user_id = p_user_id;
  RETURN TRUE;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies

-- user_profiles
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- wallets
DROP POLICY IF EXISTS "users_manage_own_wallets" ON public.wallets;
CREATE POLICY "users_manage_own_wallets"
ON public.wallets
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- transactions
DROP POLICY IF EXISTS "users_manage_own_transactions" ON public.transactions;
CREATE POLICY "users_manage_own_transactions"
ON public.transactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS set_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER set_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_wallets_updated_at ON public.wallets;
CREATE TRIGGER set_wallets_updated_at
  BEFORE UPDATE ON public.wallets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_transactions_updated_at ON public.transactions;
CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 8. Mock Data
DO $$
DECLARE
  demo_uuid UUID := gen_random_uuid();
BEGIN
  -- Create demo auth user (trigger will create user_profile + wallet)
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
    is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
    recovery_token, recovery_sent_at, email_change_token_new, email_change,
    email_change_sent_at, email_change_token_current, email_change_confirm_status,
    reauthentication_token, reauthentication_sent_at, phone, phone_change,
    phone_change_token, phone_change_sent_at
  ) VALUES (
    demo_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'demo@vtuportal.ng', crypt('Demo@2026', gen_salt('bf', 10)), now(), now(), now(),
    jsonb_build_object('full_name', 'Chukwuemeka Okafor', 'phone', '08031456789'),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
    false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
  ) ON CONFLICT (id) DO NOTHING;

  -- Seed wallet balance for demo user
  UPDATE public.wallets SET balance = 47850.00, bonus_balance = 500.00 WHERE user_id = demo_uuid;

  -- Seed demo transactions
  INSERT INTO public.transactions (id, user_id, reference, tx_type, network, phone, plan, amount, status, created_at)
  VALUES
    (gen_random_uuid(), demo_uuid, 'VTP-240607-8842', 'data'::public.transaction_type, 'MTN', '08031456789', '5GB / 30 Days', 1200.00, 'success'::public.transaction_status, now() - interval '1 hour'),
    (gen_random_uuid(), demo_uuid, 'VTP-240607-8841', 'airtime'::public.transaction_type, 'Airtel', '07065432198', 'Airtime Top-up', 500.00, 'success'::public.transaction_status, now() - interval '2 hours'),
    (gen_random_uuid(), demo_uuid, 'VTP-240607-8835', 'data'::public.transaction_type, 'Glo', '08154321876', '2GB / 7 Days', 450.00, 'failed'::public.transaction_status, now() - interval '3 hours'),
    (gen_random_uuid(), demo_uuid, 'VTP-240606-8821', 'data'::public.transaction_type, 'MTN', '08098765432', '10GB / 30 Days', 2200.00, 'success'::public.transaction_status, now() - interval '1 day'),
    (gen_random_uuid(), demo_uuid, 'VTP-240606-8819', 'data'::public.transaction_type, '9mobile', '08123456789', '1GB / 7 Days', 350.00, 'pending'::public.transaction_status, now() - interval '1 day 1 hour')
  ON CONFLICT (reference) DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
