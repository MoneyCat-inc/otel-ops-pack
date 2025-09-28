/**
 * Main Dashboard - Intuitive Navigation Hub
 * 
 * UI-01: Clean, intuitive dashboard with clear navigation
 * Replaces confusing barebones interface with user-friendly design
 */

'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState('overview');

  const navigationItems = [
    {
      id: 'overview',
      name: 'Overview',
      icon: '📊',
      description: 'System status and quick stats',
      href: '/'
    },
    {
      id: 'listen',
      name: 'Voice Analysis',
      icon: '🎤',
      description: 'Real-time voice analysis and monitoring',
      href: '/listen'
    },
    {
      id: 'practice',
      name: 'Practice Session',
      icon: '🎯',
      description: 'Guided voice practice with feedback',
      href: '/practice'
    },
    {
      id: 'labs',
      name: 'Memory Labs',
      icon: '🧪',
      description: 'Advanced memory monitoring and analysis',
      href: '/labs/memx'
    }
  ];

  const quickStats = [
    {
      title: 'System Status',
      value: 'Online',
      status: 'success',
      icon: '✅'
    },
    {
      title: 'Audio Pipeline',
      value: 'Ready',
      status: 'success',
      icon: '🎵'
    },
    {
      title: 'Memory Monitoring',
      value: 'Active',
      status: 'success',
      icon: '🧠'
    },
    {
      title: 'Cross-Origin Isolation',
      value: 'Enabled',
      status: 'success',
      icon: '🔒'
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">R</span>
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Resonai</h1>
                <p className="text-sm text-gray-600">Voice Analysis Platform</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="text-sm text-gray-600">
                <span className="inline-block w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                System Online
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Welcome Section */}
        <div className="mb-8">
          <h2 className="text-3xl font-bold text-gray-900 mb-2">Welcome to Resonai</h2>
          <p className="text-lg text-gray-600 max-w-3xl">
            Your voice analysis and practice platform. Choose from the options below to get started with voice monitoring, 
            practice sessions, or advanced memory analysis.
          </p>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {quickStats.map((stat, index) => (
            <div key={index} className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
                </div>
                <div className="text-3xl">{stat.icon}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Main Navigation Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
          {navigationItems.map((item) => (
            <Link
              key={item.id}
              href={item.href}
              className="group bg-white rounded-xl shadow-sm hover:shadow-md transition-all duration-200 border border-gray-200 hover:border-blue-300"
            >
              <div className="p-8">
                <div className="flex items-start space-x-4">
                  <div className="text-4xl group-hover:scale-110 transition-transform duration-200">
                    {item.icon}
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold text-gray-900 group-hover:text-blue-600 transition-colors">
                      {item.name}
                    </h3>
                    <p className="text-gray-600 mt-2 leading-relaxed">
                      {item.description}
                    </p>
                    <div className="mt-4 flex items-center text-blue-600 group-hover:text-blue-700">
                      <span className="text-sm font-medium">Get Started</span>
                      <svg className="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>

        {/* Getting Started Guide */}
        <div className="bg-white rounded-xl shadow-sm p-8 border border-gray-200">
          <h3 className="text-xl font-semibold text-gray-900 mb-4">🚀 Getting Started</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="flex items-start space-x-3">
              <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-blue-600 font-semibold text-sm">1</span>
              </div>
              <div>
                <h4 className="font-medium text-gray-900">Start Voice Analysis</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Click "Voice Analysis" to begin real-time voice monitoring with live feedback.
                </p>
              </div>
            </div>
            
            <div className="flex items-start space-x-3">
              <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-green-600 font-semibold text-sm">2</span>
              </div>
              <div>
                <h4 className="font-medium text-gray-900">Practice Your Voice</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Use "Practice Session" for guided voice exercises with structured feedback.
                </p>
              </div>
            </div>
            
            <div className="flex items-start space-x-3">
              <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-purple-600 font-semibold text-sm">3</span>
              </div>
              <div>
                <h4 className="font-medium text-gray-900">Advanced Analysis</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Explore "Memory Labs" for detailed memory monitoring and performance metrics.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* System Information */}
        <div className="mt-8 bg-gray-50 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">ℹ️ System Information</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <span className="font-medium text-gray-700">Platform:</span>
              <span className="ml-2 text-gray-600">Next.js 14 + WebAudio</span>
            </div>
            <div>
              <span className="font-medium text-gray-700">Audio Pipeline:</span>
              <span className="ml-2 text-gray-600">AudioWorklet + Low Latency</span>
            </div>
            <div>
              <span className="font-medium text-gray-700">Security:</span>
              <span className="ml-2 text-gray-600">COOP/COEP Enabled</span>
            </div>
            <div>
              <span className="font-medium text-gray-700">Storage:</span>
              <span className="ml-2 text-gray-600">IndexedDB Local Storage</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}