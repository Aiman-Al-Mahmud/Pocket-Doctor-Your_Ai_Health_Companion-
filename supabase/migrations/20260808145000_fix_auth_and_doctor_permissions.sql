-- Supabase Migration: Fix Doctor Auth & Permissions
-- Grants permissions and ensures doctor login works seamlessly

-- 1. Grant access to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- 2. Ensure RLS policies allow doctor lookup
DROP POLICY IF EXISTS "Public can view doctor users" ON public.users;
CREATE POLICY "Public can view doctor users" ON public.users
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can insert users" ON public.users;
CREATE POLICY "Public can insert users" ON public.users
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public can update users" ON public.users;
CREATE POLICY "Public can update users" ON public.users
    FOR UPDATE USING (true);

-- 3. Ensure Doctor Table Policies
DROP POLICY IF EXISTS "Public can view doctors" ON public.doctors;
CREATE POLICY "Public can view doctors" ON public.doctors
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can insert doctors" ON public.doctors;
CREATE POLICY "Public can insert doctors" ON public.doctors
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public can update doctors" ON public.doctors;
CREATE POLICY "Public can update doctors" ON public.doctors
    FOR UPDATE USING (true);

-- 4. Auto-confirm emails for newly registered doctors in auth.users so password login works immediately
CREATE OR REPLACE FUNCTION public.handle_auto_confirm_doctor()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.raw_user_meta_data->>'role' = 'doctor' OR NEW.email LIKE '%@hospital.com' OR NEW.email LIKE '%@doctor.com') THEN
        NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, NOW());
        NEW.confirmed_at = COALESCE(NEW.confirmed_at, NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_doctor ON auth.users;
CREATE TRIGGER on_auth_user_created_doctor
    BEFORE INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_auto_confirm_doctor();

-- 5. Confirm all existing doctor accounts
UPDATE auth.users 
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    confirmed_at = COALESCE(confirmed_at, NOW())
WHERE raw_user_meta_data->>'role' = 'doctor' 
   OR email = 'dr.sadik@hospital.com'
   OR email = 'dr.smith@hospital.com';
