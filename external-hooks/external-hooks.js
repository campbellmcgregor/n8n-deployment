/**
 * n8n External Hooks Configuration
 *
 * This file allows you to extend n8n with custom backend functionality.
 * External hooks are executed at specific points in n8n's lifecycle,
 * allowing you to implement custom business logic, logging, integrations, etc.
 *
 * Documentation: https://docs.n8n.io/hosting/configuration/external-hooks/
 */

module.exports = {
  // Workflow-related hooks
  workflow: {
    // Executed when a workflow is activated
    activate: [
      async function (workflowData, workflow) {
        console.log(`🟢 [${new Date().toISOString()}] Workflow activated:`, {
          id: workflow.id,
          name: workflow.name,
          active: workflow.active,
          nodeCount: workflow.nodes ? workflow.nodes.length : 0,
        });

        // Example: Send notification to external service
        // await notifyExternalService('workflow_activated', workflow);

        // Example: Log to custom analytics
        // await analytics.track('workflow_activated', {
        //   workflow_id: workflow.id,
        //   workflow_name: workflow.name,
        //   user_id: workflowData.userId,
        //   timestamp: new Date().toISOString()
        // });
      },
    ],

    // Executed when a workflow is deactivated
    deactivate: [
      async function (workflowData, workflow) {
        console.log(`🔴 [${new Date().toISOString()}] Workflow deactivated:`, {
          id: workflow.id,
          name: workflow.name,
          active: workflow.active,
        });
      },
    ],

    // Executed before a workflow starts executing
    beforeExecute: [
      async function (workflowData, runData) {
        console.log(
          `▶️ [${new Date().toISOString()}] Workflow execution started:`,
          {
            workflowId: workflowData.workflow?.id,
            workflowName: workflowData.workflow?.name,
            executionId: runData.executionId,
            mode: runData.executionMode,
            startedAt: runData.startedAt,
          }
        );

        // Example: Check execution limits
        // const activeExecutions = await getActiveExecutionCount(workflowData.workflow.id);
        // if (activeExecutions > 5) {
        //   throw new Error('Too many concurrent executions for this workflow');
        // }
      },
    ],

    // Executed after a workflow finishes executing
    afterExecute: [
      async function (workflowData, runData) {
        const duration = runData.stoppedAt
          ? new Date(runData.stoppedAt).getTime() -
            new Date(runData.startedAt).getTime()
          : null;

        console.log(
          `⏹️ [${new Date().toISOString()}] Workflow execution finished:`,
          {
            workflowId: workflowData.workflow?.id,
            workflowName: workflowData.workflow?.name,
            executionId: runData.executionId,
            status: runData.status,
            duration: duration ? `${duration}ms` : "unknown",
            finished: runData.finished,
          }
        );

        // Example: Store execution metrics
        // await storeExecutionMetrics({
        //   workflow_id: workflowData.workflow?.id,
        //   execution_id: runData.executionId,
        //   duration: duration,
        //   status: runData.status,
        //   node_count: Object.keys(runData.data?.resultData?.runData || {}).length
        // });
      },
    ],
  },

  // Credential-related hooks
  credentials: {
    // Executed when a credential is created
    create: [
      async function (credentialData) {
        console.log(`🔑 [${new Date().toISOString()}] Credential created:`, {
          id: credentialData.id,
          name: credentialData.name,
          type: credentialData.type,
        });

        // Example: Audit logging
        // await auditLog.create({
        //   action: 'credential_created',
        //   resource_type: 'credential',
        //   resource_id: credentialData.id,
        //   user_id: credentialData.userId,
        //   timestamp: new Date()
        // });
      },
    ],

    // Executed when a credential is updated
    update: [
      async function (credentialData) {
        console.log(`🔄 [${new Date().toISOString()}] Credential updated:`, {
          id: credentialData.id,
          name: credentialData.name,
          type: credentialData.type,
        });
      },
    ],

    // Executed when a credential is deleted
    delete: [
      async function (credentialData) {
        console.log(`🗑️ [${new Date().toISOString()}] Credential deleted:`, {
          id: credentialData.id,
          name: credentialData.name,
          type: credentialData.type,
        });

        // Example: Clean up related resources
        // await cleanupRelatedResources(credentialData.id);
      },
    ],
  },

  // User-related hooks (if user management is enabled)
  user: {
    // Executed when a user is created
    create: [
      async function (userData) {
        console.log(`👤 [${new Date().toISOString()}] User created:`, {
          id: userData.id,
          email: userData.email,
          firstName: userData.firstName,
          lastName: userData.lastName,
        });

        // Example: Send welcome email
        // await sendWelcomeEmail(userData.email, userData.firstName);

        // Example: Add to external CRM
        // await crm.addUser({
        //   email: userData.email,
        //   name: `${userData.firstName} ${userData.lastName}`,
        //   source: 'n8n_signup'
        // });
      },
    ],

    // Executed when a user is updated
    update: [
      async function (userData) {
        console.log(`👤 [${new Date().toISOString()}] User updated:`, {
          id: userData.id,
          email: userData.email,
        });
      },
    ],

    // Executed when a user is deleted
    delete: [
      async function (userData) {
        console.log(`👤 [${new Date().toISOString()}] User deleted:`, {
          id: userData.id,
          email: userData.email,
        });
      },
    ],
  },

  // Node-related hooks
  node: {
    // Executed before a node executes
    beforeExecute: [
      async function (nodeData, inputData, executionId) {
        // Only log for specific node types to avoid noise
        const loggedNodeTypes = [
          "n8n-nodes-base.webhook",
          "n8n-nodes-base.httpRequest",
        ];

        if (loggedNodeTypes.includes(nodeData.type)) {
          console.log(`🔧 [${new Date().toISOString()}] Node executing:`, {
            nodeName: nodeData.name,
            nodeType: nodeData.type,
            executionId: executionId,
            inputItemCount: inputData[0]?.length || 0,
          });
        }
      },
    ],

    // Executed after a node executes
    afterExecute: [
      async function (nodeData, outputData, executionId) {
        // Log errors or important node executions
        if (
          outputData[0]?.error ||
          nodeData.type === "n8n-nodes-base.webhook"
        ) {
          console.log(`🔧 [${new Date().toISOString()}] Node executed:`, {
            nodeName: nodeData.name,
            nodeType: nodeData.type,
            executionId: executionId,
            hasError: !!outputData[0]?.error,
            outputItemCount: outputData[0]?.length || 0,
          });
        }
      },
    ],
  },

  // Database-related hooks
  database: {
    // Executed when n8n connects to the database
    connect: [
      async function () {
        console.log(`🗄️ [${new Date().toISOString()}] Database connected`);

        // Example: Initialize custom tables or data
        // await initializeCustomTables();
      },
    ],
  },
};

// Helper functions (examples)

/**
 * Example function to send notifications to external services
 */
// async function notifyExternalService(event, data) {
//   try {
//     // Example: Slack notification
//     // await fetch('https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK', {
//     //   method: 'POST',
//     //   headers: { 'Content-Type': 'application/json' },
//     //   body: JSON.stringify({
//     //     text: `n8n ${event}: ${data.name || data.id}`
//     //   })
//     // });
//   } catch (error) {
//     console.error('Failed to send external notification:', error);
//   }
// }

/**
 * Example function for analytics tracking
 */
// const analytics = {
//   async track(event, properties) {
//     try {
//       // Example: Send to analytics service
//       // await fetch('https://api.analytics-service.com/track', {
//       //   method: 'POST',
//       //   headers: {
//       //     'Content-Type': 'application/json',
//       //     'Authorization': 'Bearer ' + process.env.ANALYTICS_API_KEY
//       //   },
//       //   body: JSON.stringify({ event, properties })
//       // });
//     } catch (error) {
//       console.error('Analytics tracking failed:', error);
//     }
//   }
// };

/**
 * Example function for audit logging
 */
// const auditLog = {
//   async create(logEntry) {
//     try {
//       // Store audit log in database or external service
//       console.log('AUDIT:', logEntry);
//     } catch (error) {
//       console.error('Audit logging failed:', error);
//     }
//   }
// };
