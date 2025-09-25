/**
 * ECRR Dashboard API
 * RESTful endpoints for dashboard and KPI data
 */

import { Request, Response } from 'express';
import { KPICalculator } from '../dashboard/kpi-calculator';

export class DashboardAPI {
  constructor(private kpiCalculator: KPICalculator) {}

  /**
   * Get main dashboard data
   */
  async getDashboard(req: Request, res: Response): Promise<void> {
    try {
      const dashboard = await this.kpiCalculator.calculateDashboard();
      
      res.status(200).json({
        dashboard,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting dashboard:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get specific KPI data
   */
  async getKPI(req: Request, res: Response): Promise<void> {
    try {
      const kpiId = req.params.id;
      const days = parseInt(req.query.days as string) || 30;

      const trendData = await this.kpiCalculator.getKPITrends(kpiId, days);
      
      res.status(200).json({
        kpiId,
        period: `${days} days`,
        data: trendData,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting KPI:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get critical alerts
   */
  async getAlerts(req: Request, res: Response): Promise<void> {
    try {
      const alerts = await this.kpiCalculator.getCriticalAlerts();
      
      res.status(200).json({
        alerts,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting alerts:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get automation coverage details
   */
  async getAutomationCoverage(req: Request, res: Response): Promise<void> {
    try {
      const days = parseInt(req.query.days as string) || 30;
      const coverage = await this.kpiCalculator.calculateAutomationCoverage();
      const trend = await this.kpiCalculator.getKPITrends('automation-coverage', days);
      
      res.status(200).json({
        coverage,
        trend,
        period: `${days} days`,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting automation coverage:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get SLA compliance details
   */
  async getSlaCompliance(req: Request, res: Response): Promise<void> {
    try {
      const days = parseInt(req.query.days as string) || 30;
      const trend = await this.kpiCalculator.getKPITrends('sla-compliance', days);
      
      // Get current SLA compliance from dashboard
      const dashboard = await this.kpiCalculator.calculateDashboard();
      
      res.status(200).json({
        compliance: dashboard.performance.slaComplianceRate,
        trend,
        period: `${days} days`,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting SLA compliance:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get workload distribution
   */
  async getWorkloadDistribution(req: Request, res: Response): Promise<void> {
    try {
      const dashboard = await this.kpiCalculator.calculateDashboard();
      const workload = dashboard.workload;
      
      res.status(200).json({
        workload,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting workload distribution:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get performance metrics
   */
  async getPerformanceMetrics(req: Request, res: Response): Promise<void> {
    try {
      const dashboard = await this.kpiCalculator.calculateDashboard();
      const performance = dashboard.performance;
      
      res.status(200).json({
        performance,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting performance metrics:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get trend data for specific metric
   */
  async getTrendData(req: Request, res: Response): Promise<void> {
    try {
      const { metric } = req.params;
      const days = parseInt(req.query.days as string) || 30;
      
      const trend = await this.kpiCalculator.getKPITrends(metric, days);
      
      res.status(200).json({
        metric,
        trend,
        period: `${days} days`,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error getting trend data:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
