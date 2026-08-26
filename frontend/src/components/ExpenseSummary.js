import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

function ExpenseSummary({ summary }) {
  const data = Object.entries(summary).map(([category, amount]) => ({
    category,
    amount,
  }));

  return (
    <div>
      <h2>Summary by Category</h2>
      {data.length === 0 ? (
        <p>No data yet</p>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="category" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="amount" fill="#8884d8" />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

export default ExpenseSummary;