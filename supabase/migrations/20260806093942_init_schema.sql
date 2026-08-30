-- Pocket Doctor Ecosystem - Supabase Production Schema
-- Database Reference: woimsjvxbocisrdxgzls

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE (Base profile linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('patient', 'doctor', 'admin')),
    avatar_url TEXT,
    phone_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. PATIENTS TABLE
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    blood_group TEXT,
    medical_history TEXT,
    emergency_contact TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. DOCTORS TABLE
CREATE TABLE IF NOT EXISTS public.doctors (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    medical_license_number TEXT UNIQUE NOT NULL,
    qualification TEXT NOT NULL,
    specialization TEXT NOT NULL,
    hospital_affiliation TEXT,
    years_of_experience INT DEFAULT 0,
    biography TEXT,
    consultation_fee NUMERIC(10, 2) DEFAULT 0.00,
    rating NUMERIC(3, 2) DEFAULT 5.00,
    is_verified BOOLEAN DEFAULT FALSE,
    availability_status TEXT DEFAULT 'available' CHECK (availability_status IN ('available', 'busy', 'offline')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CHATS TABLE (Patient AI Conversations)
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Health Consultation',
    medical_division TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. MESSAGES TABLE (AI Chat Messages)
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'ai')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. REVIEW REQUESTS TABLE (AI Responses Submitted for Doctor Validation)
CREATE TABLE IF NOT EXISTS public.review_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES public.chats(id) ON DELETE SET NULL,
    user_query TEXT NOT NULL,
    ai_response_content TEXT NOT NULL,
    medical_division TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'completed', 'rejected')),
    assigned_doctor_id UUID REFERENCES public.doctors(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. DOCTOR REVIEWS TABLE (Doctor's Feedback / Approval)
CREATE TABLE IF NOT EXISTS public.doctor_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_request_id UUID UNIQUE NOT NULL REFERENCES public.review_requests(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    approval_status TEXT NOT NULL CHECK (approval_status IN ('approved', 'corrected', 'emergency_flagged')),
    doctor_advice TEXT NOT NULL,
    recommendation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. AVAILABILITY SLOTS TABLE (Doctor's Available Slots)
CREATE TABLE IF NOT EXISTS public.availability_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Monday, 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_booked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. APPOINTMENTS TABLE
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
    slot_id UUID REFERENCES public.availability_slots(id) ON DELETE SET NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. DOCTOR PRESENCE TABLE
CREATE TABLE IF NOT EXISTS public.doctor_presence (
    doctor_id UUID PRIMARY KEY REFERENCES public.doctors(id) ON DELETE CASCADE,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.availability_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_presence ENABLE ROW LEVEL SECURITY;

-- Public Users Policy
CREATE POLICY "Users can read own profile or doctors" ON public.users
    FOR SELECT USING (auth.uid() = id OR role = 'doctor');

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Patient Policies
CREATE POLICY "Patients access own profile" ON public.patients
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Doctors view patient profiles for reviews/appointments" ON public.patients
    FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'doctor'));

-- Doctor Policies
CREATE POLICY "Anyone can view doctor profiles" ON public.doctors
    FOR SELECT USING (true);

CREATE POLICY "Doctors update own profile" ON public.doctors
    FOR UPDATE USING (auth.uid() = id);

-- Review Requests Policies
CREATE POLICY "Patients manage own review requests" ON public.review_requests
    FOR ALL USING (auth.uid() = patient_id);

CREATE POLICY "Doctors view & update review requests" ON public.review_requests
    FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'doctor'));

-- Doctor Reviews Policies
CREATE POLICY "Patients & Doctors view doctor reviews" ON public.doctor_reviews
    FOR SELECT USING (auth.uid() = patient_id OR auth.uid() = doctor_id);

CREATE POLICY "Doctors create reviews" ON public.doctor_reviews
    FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'doctor'));

-- Appointments Policies
CREATE POLICY "Patients manage own appointments" ON public.appointments
    FOR ALL USING (auth.uid() = patient_id);

CREATE POLICY "Doctors manage assigned appointments" ON public.appointments
    FOR ALL USING (auth.uid() = doctor_id);

-- Availability Slots Policies
CREATE POLICY "Anyone view availability slots" ON public.availability_slots
    FOR SELECT USING (true);

CREATE POLICY "Doctors manage own availability slots" ON public.availability_slots
    FOR ALL USING (auth.uid() = doctor_id);

-- Realtime Publication Enablement
ALTER PUBLICATION supabase_realtime ADD TABLE public.review_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.doctor_reviews;
ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.doctor_presence;
