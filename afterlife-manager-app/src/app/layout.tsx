import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Digital Afterlife Manager | Database Dashboard",
  description: "Modern dashboard to manage and query Digital Afterlife Management database. Secure, fast, and reliable.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
