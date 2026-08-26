import React, { useState, useEffect } from 'react';
import './App.css';
import ExpenseForm from './components/ExpenseForm';
import ExpenseList from './components/ExpenseList';
import ExpenseSummary from './components/ExpenseSummary';

function App() {
  const [expenses, setExpenses] = useState([]);
  const [summary, setSummary] = useState({});
  const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

  useEffect(() => {
    // eslint-disable-next-line react-hooks/exhaustive-deps
    fetchExpenses();
    fetchSummary();
  }, []);

  const fetchExpenses = async () => {
    try {
      const response = await fetch(`${API_URL}/expenses`);
      setExpenses(await response.json());
    } catch (error) {
      console.error('Error fetching expenses:', error);
    }
  };

  const fetchSummary = async () => {
    try {
      const response = await fetch(`${API_URL}/expenses/summary`);
      setSummary(await response.json());
    } catch (error) {
      console.error('Error fetching summary:', error);
    }
  };

  const handleAddExpense = async (expense) => {
    try {
      await fetch(`${API_URL}/expenses`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(expense),
      });
      fetchExpenses();
      fetchSummary();
    } catch (error) {
      console.error('Error adding expense:', error);
    }
  };

  const handleDeleteExpense = async (id) => {
    try {
      await fetch(`${API_URL}/expenses/${id}`, { method: 'DELETE' });
      fetchExpenses();
      fetchSummary();
    } catch (error) {
      console.error('Error deleting expense:', error);
    }
  };

  return (
    <div className="App">
      <h1>Expense Tracker</h1>
      <ExpenseForm onAddExpense={handleAddExpense} />
      <ExpenseSummary summary={summary} />
      <ExpenseList expenses={expenses} onDeleteExpense={handleDeleteExpense} />
    </div>
  );
}

export default App;