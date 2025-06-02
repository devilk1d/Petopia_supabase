-- Drop RLS policies for orders
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Sellers can view their product orders" ON public.orders;
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;

-- Drop RLS policies for order_items
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Sellers can view their product order items" ON public.order_items;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY; 