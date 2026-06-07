import './globals.css'; // Ensure you have your CSS imports here

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="bg-slate-950 text-slate-100">
      <body className="min-h-screen flex flex-col">
        {/* Professional Top Navigation */}
        <nav className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-md p-4 flex justify-between items-center px-8">
          <h1 className="text-xl font-bold tracking-tighter text-yellow-500">ECHELON</h1>
          <div className="space-x-6 text-sm font-medium">
            <a href="/" className="hover:text-yellow-500 transition">Dashboard</a>
            <a href="/register" className="hover:text-yellow-500 transition">Portal</a>
          </div>
        </nav>

        {/* Main Content Area */}
        <main className="flex-grow container mx-auto px-4 py-8">
          {children}
        </main>

        {/* Footer */}
        <footer className="border-t border-slate-800 p-6 text-center text-slate-500 text-xs">
          © 2026 Echelon Agency. All rights reserved.
        </footer>
      </body>
    </html>
  );
}
